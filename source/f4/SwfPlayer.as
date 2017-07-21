package f4 {

  import flash.display.DisplayObject;
  import flash.display.MovieClip;
  import flash.display.Stage;
  import flash.display.Sprite;
  import flash.events.TimerEvent;
  import flash.utils.Timer;
  import flash.media.SoundTransform;

  import common.loader.PQLoader;
  import common.loader.item.SWFItem;
  import common.loader.item.AVM1MovieItem;
  import common.loader.item.AbstractItem;

  public class SwfPlayer extends MovieClip implements PlayerInterface {

    private var _contaner: Sprite;
    private var _callback: Function;
    private var _movie: MovieClip;
    private var _frameRate: int;

    public function SwfPlayer(listOrOneSwf: Array = null) {
      PQLoader.getInstance().start();
      _contaner = new Sprite();
    }

    public function Movie(w: int, h: int): DisplayObject {
      return _contaner;
    }

    private function clearMovie(): void {
      if (_movie) {
        _movie.stop();
        _contaner.removeChild(_movie);
        _movie = null;
      }
    }

    public function Play(filepath: String): Boolean {
      clearMovie();
      var loader:PQLoader = PQLoader.getInstance();
      loader.addItem(filepath, AVM1MovieItem).complete(function(item: AbstractItem): void {
        var movieItem: AVM1MovieItem = item as AVM1MovieItem;
        _movie = movieItem.getMovieClip();
        _frameRate = movieItem.getLoaderInfo().frameRate;
        /*stage.frameRate = frameRate;*/
        _contaner.addChild(_movie);
        _callback({status: "NetConnection.Connect.Success", time: 0, duration: _movie.totalFrames / _frameRate});
        _movie.gotoAndPlay(1);
      });
      return true;
    }

    public function Seek(point: int): int {
      if (_movie) {
        var duration:int = Math.floor(_movie.totalFrames / _frameRate);
        if (point <= duration) {
          _movie.gotoAndPlay(Math.floor(point / duration * _movie.totalFrames));
        }
      }
      return 0;
    }

    public function Callback(callback: Function): void {
      _callback = callback;
      var timer : Timer = new Timer( 100 );
      function onTimerHanlder(e: TimerEvent): void {
        if (_movie) {
            var time:int = Math.floor(_movie.currentFrame / _frameRate);
            var duration:int = Math.floor(_movie.totalFrames / _frameRate);
            _callback({time: time, duration: duration});
            if (time >= duration) {
              _movie.stop();
            }
        }
      }
      timer.addEventListener( TimerEvent.TIMER, onTimerHanlder );
      timer.start();
    }

    public function Pause() : Boolean {
      if (_movie.isPlaying) {
        _movie.stop();
      } else {
        _movie.play();
      }
      return true;
    }

    public function Stop() : void {}

    public function Volume( vol : Number ) : void {
      var soundTransform: SoundTransform = _movie.soundTransform;
      soundTransform.volume = vol;
      _movie.soundTransform = soundTransform;
    }

    public function Mute() : Number {
      return 0;
    }

    public function Fullscreen( stage : Stage ) : Boolean {
      return true;
    }

    public function Thumbnail( image : String, w : int, h : int ) : MovieClip {
      return null;
    }

    public function Next() : void {}

    public function Prev() : void {}

    public function Subtitle( sub : String ) : void {}

    public function Log( log : String ) : void {}
  }
}
