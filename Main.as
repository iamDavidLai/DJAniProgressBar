package 
{
	import com.dj.display.DJAniProgressBar;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author David Lai
	 */
	public class Main extends Sprite {
		
		private var myAniMC:MovieClip
		private var myProgressBar:DJAniProgressBar;
		
		
		
		public function Main() {
			this.init();
		}
		
		private function init():void {
			//
			// create MovieClip, it contains timeline animation 
			//			
			this.myAniMC = new MyAniMC();
			this.addChild(this.myAniMC);
			
			//
			// create DJAniProgressBar
			//
			this.myProgressBar = new DJAniProgressBar(this.myAniMC);
			
		}
		
		
	}
	
}