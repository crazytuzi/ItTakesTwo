import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Actors.KeyedSplineCamera;

UCLASS(HideCategories = "Tick Replication Actor Input Debug LOD Cooking Collision Rendering")
class ABasementLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION()
	void SetKeepInViewVerticalOffset(AKeyedSplineCamera CameraActor, float Offset = 200.f)
	{
		UCameraKeepInViewComponent KeepInViewComp = CameraActor.KeepInViewComp;
		FHazeFocusTarget FocusTarget;
		FocusTarget.Actor = Game::GetMay();
		FocusTarget.WorldOffset = FVector(0.f, 0.f, Offset);
		KeepInViewComp.SetPrimaryTarget(FocusTarget);
	}
}