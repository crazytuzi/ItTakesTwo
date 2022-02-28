import Vino.Camera.Components.CameraUserComponent;
class UDebugAudioCollider : USphereComponent
{	
	default SetSphereRadius(50.f);
	default SetCollisionObjectType(ECollisionChannel::Audio);	
	FString SelectedActorName;	

	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CameraUser = UCameraUserComponent::Get(Owner);
		AHazeDebugCameraActor DebugCamera = CameraUser.DebugCamera;
		AttachTo(DebugCamera.RootComponent, AttachType = EAttachLocation::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if(CameraUser.bUsingDebugCamera == false)		
		{
			bGenerateOverlapEvents = false;			
		}	

		if(bGenerateOverlapEvents)
		{
			Print("AmbientZone-Overlap Debug active on: " + SelectedActorName, Color = FLinearColor::Green);				
		}			
	}

	UFUNCTION(BlueprintCallable)
	void EnableAudioDebugCollision(AHazePlayerCharacter Player)
	{
		SelectedActorName = Player.GetName();
		if (!Game::IsEditorBuild())
			return;

		bGenerateOverlapEvents = true;		
	}

}