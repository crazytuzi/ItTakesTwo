import Peanuts.Visualization.DummyVisualizationComponent;

UCLASS(hideCategories="CameraVolume PointOfInterest BrushSettings HLOD Mobile Physics Collision Replication LOD Input Actor Rendering Cooking")
class ASelectBestCameraVolume : AHazeCameraVolume
{
	UPROPERTY()
	TArray<AHazeCameraActor> Cameras;

	UPROPERTY(DefaultComponent, NotVisible, BlueprintHidden)
	UDummyVisualizationComponent DummyVisualizationComp;
	default DummyVisualizationComp.Color = FLinearColor::Yellow;
	default DummyVisualizationComp.DashSize = 20.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (AHazeCameraActor Cam : Cameras)
		{
			DummyVisualizationComp.ConnectedActors.Add(Cam);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// In case we've got a separate camera on the settings component we want it as a camera candidate as well
		if (CameraSettings.Camera != nullptr)
			Cameras.AddUnique(CameraSettings.Camera);
		
		OnPreEntered.AddUFunction(this, n"OnPreEnteredVolume");
	}

	UFUNCTION()
	void OnPreEnteredVolume(UHazeCameraUserComponent User)
	{
		// Someone is about to activate the settings component camera, set that to best camera
		// Currently best camera is always the one most aligned with user view rotation, add an enum if we want different selections
		AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
		if (PlayerUser == nullptr)
			return;
		FVector ViewDir = PlayerUser.GetPlayerViewRotation().Vector();
		float BestDot = -1.1f;
		for (AHazeCameraActor Cam : Cameras)
		{
			float Dot = ViewDir.DotProduct(Cam.GetActorForwardVector());
			if (Dot > BestDot)
			{
				BestDot = Dot;
				SetActiveCamera(Cam);
			}
		}
	}
}