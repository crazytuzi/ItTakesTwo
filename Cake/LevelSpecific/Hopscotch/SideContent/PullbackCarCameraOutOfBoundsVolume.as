import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;
import Vino.Camera.Components.CameraFollowViewComponent;
import Vino.Camera.Components.FocusTrackerComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;

class APullbackCarCameraOutOfBoundsVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OutOfBounds;

	UPROPERTY(DefaultComponent)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraFollowViewComponent ViewFollower;

	UPROPERTY(DefaultComponent, Attach = ViewFollower)
	UFocusTrackerComponent FocusTracker;
	default FocusTracker.RotationSpeed = 20.f;

	UPROPERTY(DefaultComponent, Attach = FocusTracker)
	UHazeCameraComponent Camera;

	AHazePlayerCharacter ActivePlayer = nullptr;
	UPlayerRespawnComponent RespawnComp;

	UPROPERTY()
	FHazeCameraBlendSettings CameraBlend;
	default CameraBlend.BlendTime = 3.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CameraRoot.SetWorldScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OutOfBounds.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionOverlap");
	}

	UFUNCTION()
	void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		APullbackCar Car = Cast<APullbackCar>(OtherActor);
		if (Car == nullptr)
			return;

		// A player might be hitting the volume twice 
		// If we somehow launch two cars we should definitely ignore the second one as well.
		if (ActivePlayer != nullptr) 
			return; 

		ActivePlayer = nullptr;
		if (Game::Cody.AttachParentActor == Car)
			ActivePlayer = Game::Cody;
		else if (Game::May.AttachParentActor == Car)
			ActivePlayer = Game::May;
		if (ActivePlayer == nullptr)
			return;

		RespawnComp = UPlayerRespawnComponent::Get(ActivePlayer);
		if (RespawnComp == nullptr)
			return;

		RespawnComp.OnRespawn.AddUFunction(this, n"PlayerRespawned");
		System::SetTimer(this, n"OnCameraSafetyTimeout", 7.f, false);

		// Locally simulated is fine
		// Activate our custom camera
		CameraRoot.ActivateCamera(ActivePlayer, CameraBlend, this, EHazeCameraPriority::Low);

		// Widen clamps since car clamps them tight
		FHazeCameraClampSettings Clamps;
		Clamps.bUseClampPitchDown = true;
		Clamps.bUseClampPitchUp = true;
		Clamps.bUseClampYawLeft = true;
		Clamps.bUseClampYawRight = true;
		Clamps.ClampPitchDown = 89.f;
		Clamps.ClampPitchUp = 89.f;
		Clamps.ClampYawLeft = 180.f;
		Clamps.ClampYawRight = 180.f;
		ActivePlayer.ApplyCameraClampSettings(Clamps, CameraBlend, this, EHazeCameraPriority::High);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		ensure(Player == ActivePlayer);
		DeactivateCamera(-1.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCameraSafetyTimeout()
	{
		// You can e.g. make this happen with high latency if you exit the vehicle on your control side 
		// after the vehicle hits the out of bounds trigger on the car's control side.
		DeactivateCamera(5.f);
	}

	void DeactivateCamera(float BlendTime)
	{
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.Unbind(this, n"PlayerRespawned");

		if (ActivePlayer == nullptr)
			return;

		ActivePlayer.DeactivateCameraByInstigator(this, BlendTime);
		ActivePlayer.ClearCameraSettingsByInstigator(this);
		ActivePlayer = nullptr;
		RespawnComp = nullptr;
		System::ClearTimer(this, n"OnCameraSafetyTimeout");
	}
}
