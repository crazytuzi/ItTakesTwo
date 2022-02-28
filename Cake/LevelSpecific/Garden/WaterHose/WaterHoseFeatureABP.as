import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;

class UHazeWaterHozeAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY()
	AHazePlayerCharacter PlayerOwner;

	UPROPERTY()
	ULocomotionFeatureWaterHose WaterHoseFeature;

	UPROPERTY()
	UWaterHoseComponent WaterHoseComponent;

	UPROPERTY()
	FTransform SickleSocketTransform;
	
	UPROPERTY()
	float EnterAnimationLength = 0.6;

	UPROPERTY()
	float PlayedAnimLength = 0;

	UPROPERTY()
	bool GoToAim = false;

	UPROPERTY()
	bool IsMoving = false;

	UPROPERTY()
	bool CanExit = false;

	bool bUpdateEnterTime = true;
	float AimValue = 0;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwningActor());

		if(PlayerOwner != nullptr)
		{
			WaterHoseFeature = Cast<ULocomotionFeatureWaterHose>(GetFeatureAsClass(ULocomotionFeatureWaterHose::StaticClass()));
			EnterAnimationLength = WaterHoseFeature.MhToAim.Sequence.GetPlayLength();
			WaterHoseComponent = UWaterHoseComponent::Get(PlayerOwner);
			CanExit = false;
			GoToAim = false;
			PlayedAnimLength = 0;
			AimValue = 0;
		}					
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(PlayerOwner != nullptr)
		{
			// float WantedAimValue = PlayerOwner.GetControlRotation().ForwardVector.DotProduct(PlayerOwner.GetMovementWorldUp());
			// WantedAimValue = FMath::Lerp(WantedAimValue, WaterHoseComponent.AimValue, FMath::Abs(WaterHoseComponent.AimValue));
			// AimValue = FMath::FInterpConstantTo(AimValue, WantedAimValue, DeltaTime, 1.0f);
			AimValue = WaterHoseComponent.AimValue;

			IsMoving = !PlayerOwner.ActorVelocity.IsNearlyZero(Tolerance = 10.0f);
			if(WaterHoseComponent != nullptr)
			{
				SickleSocketTransform = WaterHoseComponent.WaterHose.GunMesh.GetSocketTransform(n"LeftAttach");
			}

			if (WaterHoseComponent.bWaterHoseActive)
			{
				PlayedAnimLength = FMath::Clamp(PlayedAnimLength + DeltaTime, 0, EnterAnimationLength);
			}
			else 
			{
				PlayedAnimLength = FMath::Clamp(PlayedAnimLength - DeltaTime, 0, EnterAnimationLength);
			}

			WaterHoseComponent.WaterHose.SetAnimFloatParam(n"OwnerPlayedAnimLength", PlayedAnimLength);	
		}
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetAimingAngle() const
	{
		return AimValue;
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetAimingAngleModified() const
	{
		return GetAimingAngle();
	}


}