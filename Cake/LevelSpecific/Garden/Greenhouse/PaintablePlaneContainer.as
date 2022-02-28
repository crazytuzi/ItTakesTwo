
import Cake.Environment.GPUSimulations.PaintablePlane;

class APaintablePlaneContainer : AHazeActor
{
 	UPROPERTY(EditInstanceOnly)
	APaintablePlane PaintablePlane;

 	UPROPERTY()
	bool UseLargeGoopSplashEffect = false;
}
