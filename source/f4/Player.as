/*
 ═ f4.Player ═════════════════════════════════════════════════════════════
 Software: f4.Player - flash video player
 Version: 1.3.5
 Support: http://gokercebeci.com/dev/f4player
 Author: goker.cebeci
 Contact: http://gokercebeci.com
 -------------------------------------------------------------------------
 License: Distributed under the GNU General Public License (GPLv3)
 http://www.gnu.org/copyleft/gpl.html
 This program is distributed in the hope that it will be useful - WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE.
 ═══════════════════════════════════════════════════════════════════════════ */
package f4
{

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.display.StageDisplayState;
    import flash.events.AsyncErrorEvent;
    import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.media.SoundTransform;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.URLRequest;
    import flash.utils.Timer;

    public class Player extends MovieClip implements PlayerInterface
    {

        public var body : MovieClip;
        private var nc : NetConnection;
        private var ns : PlayerNetStream;
        private var v : Video;
        private var st : SoundTransform;
        private var togglepause : Boolean = false;
        private var volcache : Number = 0;
        private var duration : int;
        private var videoWidth : int;
        private var videoHeight : int;
        private var status : String;
        public var callback : Function;

        public var stream : String;
        public var streamname : String;
        public var live : Boolean;
        public var subscribe : Boolean;
        public var autoplay : String;

        public function Player( stream : String = null, name : String = null, live : Boolean = false, subscribe : Boolean = false )
        {

            this.stream = stream;
            this.streamname = name;
            this.live = live;
            this.subscribe = subscribe;

            body = new MovieClip();
            body.graphics.drawRoundRect( 0, 0, 160, 90, 0, 0 );

            nc = new NetConnection();
            nc.addEventListener( NetStatusEvent.NET_STATUS, nsEvent );
            nc.addEventListener( SecurityErrorEvent.SECURITY_ERROR, securityError );
            nc.addEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncEvent );
            this.Log( 'Stream URL: ' + stream );
            //nc.call("checkBandwidth", null);
            //nc.connect(stream);
            //nc.client = this;

        }

        // EVENTS
        // =============================================================
        public function nsEvent( e : NetStatusEvent ) : void
        {
            Log( "NetStatusEvent: " + e.info.code );
            if ( status != e.info.code )
            {
                switch ( e.info.code )
                {
                    case "NetConnection.Connect.Success":
                        Log( 'NetConnection connected to ' + stream );
                        if ( subscribe )
                        {
                            nc.call( "FCSubscribe", null, streamname );
                        }
                        ns = new PlayerNetStream( nc );
                        ns.addEventListener( NetStatusEvent.NET_STATUS, nsEvent );
                        ns.addEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncEvent );
                        ns.bufferTime = 5; // buffer time 5 sec.
                        ns.onMetaData = metaDataEvent;
                        ns.onCuePoint = cuePointEvent;
                        st = new SoundTransform();
                        if ( autoplay )
                        {
                            Play( autoplay );
                        }
                        break;
                    case "NetStream.Play.StreamNotFound":
                        trace( "Stream not found: " + stream );
                        break;
                }
                status = e.info.code;
                if ( callback != null )
                    callback( Info() );
            }
        }

        public function securityError( e : SecurityErrorEvent ) : void
        {
            this.Log( "NetStatusEvent: " + e.text );
        }

        public function asyncEvent( e : AsyncErrorEvent ) : void
        {
            this.Log( "AsyncErrorEvent: " + e.text );
        }

        public function metaDataEvent( i : Object ) : void
        {
            this.Log( 'MetaData' );
            duration = i.duration;
            videoWidth = i.width;
            videoHeight = i.height;
        }

        public function cuePointEvent( i : Object ) : void
        {
            this.Log( 'Cuepoint' );
        }

        public function onBWDone() : void
        {
            this.Log( "BWDone" );
        }

        public function onFCSubscribe( i : Object ) : void
        {
            if ( i.code == "NetStream.Play.Start" )
            {
                this.Log( "Subscribe: " + i.code );
            }
        }

        public function onFCUnsubscribe( i : Object ) : void
        {
            trace( "UnSubscribe", i );
        }

        // =============================================================
        // =============================================================
        public function Callback( callback : Function ) : void
        {
            this.callback = callback;
            var timer : Timer = new Timer( 100 );
            var timerEvent : Function = function ( e : TimerEvent ) : void
            {
                var info : PlayerInfo = Info();
                if ( info.progress >= 100 )
                    timer.stop();
                if ( nc.connected )
                    callback( info );
            };
            timer.addEventListener( TimerEvent.TIMER, timerEvent );
            timer.start();
        }

        private function Info() : PlayerInfo
        {
            var info : PlayerInfo = new PlayerInfo();
            var playing : Number = ns ? Number( (ns.time / duration).toFixed( 2 ) ) : 0;
            info.width = videoWidth;
            info.height = videoHeight;
            info.total = ns ? ns.bytesTotal : 0;
            info.loaded = ns ? ns.bytesLoaded : 0;
            info.progress = Number( ns ? (ns.bytesLoaded / ns.bytesTotal).toFixed( 2 ) : 0 );
            info.duration = duration;
            info.time = ns ? ns.time : 0;
            info.playing = (playing > 1 ? 1 : playing);
            info.status = status;
            return info;
//            return {
//                'width'   : videoWidth,
//                'height'  : videoHeight,
//                'total'   : ns ? ns.bytesTotal : 0,
//                'loaded'  : ns ? ns.bytesLoaded : 0,
//                'progress': ns ? (ns.bytesLoaded / ns.bytesTotal).toFixed( 2 ) : 0,
//                'duration': duration,
//                'time'    : ns ? ns.time : 0,
//                'playing' : (playing > 1 ? 1 : playing),
//                'status'  : status
//            };
        }

        public function Movie( w : int, h : int ) : DisplayObject
        {
            this.Log( 'Video dimensions: ' + w.toString() + 'x' + h.toString() );
            v = new Video( w, h );
            v.smoothing = true;
            this.Log( 'NetConnection is: ' + nc.connected );
            v.attachNetStream( ns );
            return v as DisplayObject;
        }

        public function Play( file : String ) : Boolean
        {
            if ( nc.connected )
            {
                if ( stream )
                {
                    this.Log( "Play stream: " + streamname );
                    ns.play( streamname, live ? -1 : 1 );
                }
                else
                {
                    this.Log( "Play file: " + file );
                    ns.play( file );
                }
            }
            else
            {
                autoplay = file || streamname;
                nc.connect( stream );
                nc.client = this;
                this.Log( 'Autoplay: ' + autoplay );
            }
            return true;
        }

        public function Pause() : Boolean
        {
            this.Log( 'Pause' );
            if ( togglepause )
            {
                togglepause = false;
                ns.resume();
            }
            else
            {
                togglepause = true;
                ns.pause();
            }
            return togglepause;
        }

        public function Stop() : void
        {
            this.Log( 'Stop' );
            ns.close();
        }

        public function Volume( vol : Number ) : void
        {
            this.Log( 'Volume: ' + vol.toString() );
            st.volume = vol;
            ns.soundTransform = st;
        }

        public function Mute() : Number
        {
            if ( volcache )
            {
                this.Log( 'VolumeCache: ' + volcache.toString() );
                st.volume = volcache;
                ns.soundTransform = st;
                volcache = 0;
            }
            else
            {
                this.Log( 'Mute' );
                volcache = st.volume;
                st.volume = 0;
                ns.soundTransform = st;
            }
            return st.volume;
        }

        public function Fullscreen( stage : Stage ) : Boolean
        {
            this.Log( 'Fullscreen: ' + !(stage.displayState == StageDisplayState.FULL_SCREEN) );
            if ( stage.displayState != StageDisplayState.NORMAL )
            {
                stage.displayState = StageDisplayState.NORMAL;
                return false;
            }
            else
            {
                var vLoc : Point = v.parent.localToGlobal( new Point( v.x, v.y ) );
                stage.fullScreenSourceRect = new Rectangle( vLoc.x, vLoc.y, v.width, v.height );
                stage.displayState = StageDisplayState.FULL_SCREEN;
                return true;
            }
        }

        public function Seek( point : int ) : int
        {
            this.Log( 'Seek: ' + point.toString() );
            ns.seek( point );
            return point;
        }

        public function Thumbnail( image : String, w : int, h : int ) : MovieClip
        {
            this.Log( 'Thumbnail: ' + image );
            var mc : MovieClip = new MovieClip();
            var bmp : BitmapData = new BitmapData( w, h, false, 0x000000 );
            mc.addChild( new Bitmap( bmp ) );
            if ( image )
            {
                var l : Loader = new Loader();
                var lEvent : Function = function ( event : Event ) : void
                {
                    var image : Bitmap = l.content as Bitmap;
                    var m : Matrix = new Matrix();
                    m.scale( w / image.width, h / image.height );
                    bmp.draw( image, m, null, null, null, true );
                    image = new Bitmap( bmp );
                    mc.addChild( image );
                };
                l.contentLoaderInfo.addEventListener( Event.COMPLETE, lEvent );
                l.load( new URLRequest( image ) );
            }
            return mc;
        }

        public function Next() : void
        {
            this.Log( 'Next' );
        }

        public function Prev() : void
        {
            this.Log( 'Prev' );
        }

        public function Subtitle( sub : String ) : void
        {
            this.Log( 'Subtitle: ' + sub );
        }

        public function Log( log : String ) : void
        {
            trace( log );
//            ExternalInterface.call( "console.log", log );
        }
    }
}
