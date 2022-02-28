import Vino.Camera.Actors.StaticCamera;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;

//THIS IS NO LONGER IN USE - DELETE ONCE CONFIRMED CHANGES
class ASelfieImageThrowCameraManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor Camera;

	ASelfieCameraImage TargetImage;

	FRotator StartRot;
	FVector StartLoc;

	FVector InterpLoc;

	FHazeAcceleratedRotator AccelRot;

	float MinDistance = 1100.f;

	float DefaultFollowSpeed = 800.f;
	float FollowSpeed;

	bool bCanFollow;

	bool bTimerActive;

	float DefaultTimer = 1.2f;
	float CurrentTimer;

	UFUNCTION()
	void SetCameraFollowActive(AHazePlayerCharacter Player, ASelfieCameraImage ActiveImage)
	{
		StartLoc = Camera.ActorLocation;
		StartRot = Camera.ActorRotation;
		AccelRot.SnapTo(StartRot);

		FollowSpeed = DefaultFollowSpeed;
		
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.2f;
		Camera.ActivateCamera(Player, Blend, this);
		TargetImage = ActiveImage;
		
		bCanFollow = true;
	}

	UFUNCTION()
	void SetCameraDeactivated(AHazePlayerCharacter Player)
	{
		Camera.DeactivateCamera(Player, 1.5f);
		bCanFollow = false;
		bTimerActive = true;
		CurrentTimer = DefaultTimer;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanFollow)
		{
			float Distance = (TargetImage.ActorLocation - Camera.ActorLocation).Size();
			FVector Direction = (TargetImage.ActorLocation - Camera.ActorLocation);
			Direction.Normalize();

			if (Distance > MinDistance)
			{
				FVector MoveDelta = Direction * FollowSpeed * DeltaTime;
				FollowSpeed *= 0.99f;
				Camera.AddActorWorldOffset(MoveDelta);
			}

			FRotator LookDirection = Direction.Rotation();
			AccelRot.AccelerateTo(LookDirection, 0.5f, DeltaTime);
			Camera.SetActorRotation(AccelRot.Value);
		}
		else if (bTimerActive)
		{
			CurrentTimer -= DeltaTime;

			if (CurrentTimer <= 0.f)
			{
				bTimerActive = false;
				Camera.SetActorLocationAndRotation(StartLoc, StartRot);
			}
		}
	}
}