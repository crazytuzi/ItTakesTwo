
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;
import Vino.Camera.PointOfInterest.PointOfInterestStatics;
import Vino.Camera.Capabilities.CameraLazyChaseCapability;

class UClockworkBullBossPlayerCameraFocusCapability : UCameraLazyChaseCapability
{
	AHazePlayerCharacter Player;
	UClockWorkBullBossPlayerComponent BullBossComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		BullBossComponent = UClockWorkBullBossPlayerComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);

		SetMutuallyExclusive(CameraTags::OptionalChaseAssistance, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Super::OnDeactivated(DeactivationParams);

		SetMutuallyExclusive(CameraTags::OptionalChaseAssistance, false);
	}

	bool IsMoving() const
	{
		// If we are the target, we force the focus
		if(GetCurrentTargetPlayer() == Player)
		{
			return true;
		}

		return Super::IsMoving();
	}

	FRotator GetTargetRotation() override
	{
		FRotator CurrentTargetRotation = Super::GetTargetRotation();

		float DistanceToBull = Player.GetDistanceTo(BullBossComponent.BullBoss);
		float DistanceToBullAlpha = FMath::Clamp(FMath::Min(DistanceToBull / 2000.f, 1.f), 0.f, 1.f);

		// The closer we are to the boss, the more important that is
		float DistanceToPillar = Player.GetDistanceTo(BullBossComponent.BullBoss.CenterPillar);
		float DistanceToPillarAlpha = FMath::Clamp(FMath::Min(DistanceToBull / 10000.f, 1.f), 0.f, 
			FMath::Lerp(1.f, 0.f, DistanceToBullAlpha));
		
		FVector CameraTargetLocation = GetCameraFocusLocation();
		
		const FVector CameraForward = (CameraTargetLocation - User.GetPivotLocation()).GetSafeNormal();
		FRotator NewTargetRotation = Math::MakeRotFromXZ(CameraForward, CurrentTargetRotation.UpVector);

		// We include a bit of the original lazy chase rotation, but mostly we focus the boss
		float ShouldFocusOriginalTargetRotation = GetCorrectCameraAlpha(NewTargetRotation);
		const bool bIsTargetedByBull = GetCurrentTargetPlayer() == Player;
		ShouldFocusOriginalTargetRotation *= FMath::Lerp(0.3f, 0.f, DistanceToPillarAlpha);
		if(bIsTargetedByBull)
			ShouldFocusOriginalTargetRotation *= 0.33f;			

		CurrentTargetRotation = FMath::LerpShortestPath(NewTargetRotation, CurrentTargetRotation, ShouldFocusOriginalTargetRotation);
		CurrentTargetRotation.Roll = 0;
		return CurrentTargetRotation;
	}

	FVector GetCameraFocusLocation() const
	{
		// The bullboss location with a bit of facing down amount
		float CollisionRadius = BullBossComponent.BullBoss.CapsuleComponent.CapsuleRadius;
		FVector BullLocation = BullBossComponent.BullBoss.GetActorLocation();
		BullLocation.Z -= CollisionRadius * 0.25f;
		return BullLocation;
	}

	float GetDeltaTimeForDelayUpdates(float DeltaTime) const
	{
		// The closer we are to the bullboss, the longer time it will take to force focus if we dont want to
		float Value = Super::GetDeltaTimeForDelayUpdates(DeltaTime);
		float DistanceToBull = Player.GetDistanceTo(BullBossComponent.BullBoss);
		float DistanceToBullAlpha = FMath::Clamp(FMath::Min(DistanceToBull / 3000.f, 1.f), 0.05f, 1.f);
		return Value * DistanceToBullAlpha;
	}

	float GetSpeedFactorMultiplier(float AngleDiff) const override
	{
		float Value = Super::GetSpeedFactorMultiplier(AngleDiff);
		// If we are the current target, we will turn the camera faster
		if(GetCurrentTargetPlayer() == Player && Super::IsMoving())
			Value += 0.5f;
		else if(GetCurrentTargetPlayer() != Player && !Super::IsMoving())
			Value *= 0.25f;

		return Value;
	}

	FRotator FinalizeDeltaRotation(float DeltaTime, FRotator DeltaRot) override
	{
		// We inlude pitch in the delta rotation
		return DeltaRot;
	}

	float GetCorrectCameraAlpha(FRotator WantedRotation)const
	{
		const FVector CameraDir = WantedRotation.ForwardVector;
		const FVector DirToBoss = (BullBossComponent.BullBoss.GetActorLocation() - Player.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		return (CameraDir.DotProduct(DirToBoss) + 1.f) * 0.5f;
	}

	AHazePlayerCharacter GetCurrentTargetPlayer()const
	{
		AHazePlayerCharacter CurrentTarget = BullBossComponent.BullBoss.GetCurrentTargetPlayer();
		if(CurrentTarget == nullptr)
			return Player;
		return CurrentTarget;
	}
}