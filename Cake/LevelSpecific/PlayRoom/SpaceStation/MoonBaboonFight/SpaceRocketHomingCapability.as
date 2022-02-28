import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocket;

class USpaceRocketHomingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	ASpaceRocket SpaceRocket;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	AHazePlayerCharacter TargetPlayer;

	FVector CurrentPlayerMovementInput;
	float CurrentPlayerRotationInput;

	FVector CurrentFacingDir;
	FVector TargetFacingDir;

	FRotator TargetRotation;

	float CurrentPitch;
	float MinRotationSpeed = 3.f;
	float MaxRotationSpeed = 15.f;

	bool bFirstActivation = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SpaceRocket = Cast<ASpaceRocket>(Owner);
		CurrentFacingDir = Owner.ActorForwardVector;
		TargetFacingDir = Owner.ActorForwardVector;
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SpaceRocket.bFollowingPlayer)
        	return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SpaceRocket.bFollowingPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetRotation = SpaceRocket.ActorRotation;
		TargetPlayer = SpaceRocket.TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpaceRocket.TriggerMovementTransition(this);
		SpaceRocket.SetActorRotation(FRotator(0.f, SpaceRocket.ActorRotation.Yaw, 0.f));

		TargetPlayer.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (TargetPlayer != nullptr)
			TargetPlayer.ClearPointOfInterestByInstigator(this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector DirToRocket = SpaceRocket.ActorLocation - TargetPlayer.ActorLocation;
		DirToRocket = Math::ConstrainVectorToPlane(DirToRocket, FVector::UpVector);
		DirToRocket.Normalize();

		if (bFirstActivation)
		{
			if (ActiveDuration >= 0.5f)
				bFirstActivation = false;
		}
		else
		{
			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
			PoISettings.FocusTarget.WorldOffset = TargetPlayer.ActorLocation + (DirToRocket * 5000.f) - FVector(0.f, 0.f, 0.f);
			PoISettings.Blend.BlendTime = 3.f;
			PoISettings.InputPauseTime = 1.5f;
			TargetPlayer.ApplyInputAssistPointOfInterest(PoISettings, this);
		}

		if (SpaceRocket.HasControl())
		{
			float HeightOffset = 100.f;
			if (TargetPlayer == Game::GetCody())
			{
				UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(TargetPlayer);
				if (ChangeSizeComp != nullptr)
				{
					if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
						HeightOffset = 10.f;
				}
			}
			FVector DirectionToPlayer = (TargetPlayer.ActorLocation + FVector(0.f, 0.f, HeightOffset)) - SpaceRocket.ActorLocation;
			TargetRotation = DirectionToPlayer.Rotation();
			float DistanceToPlayer = SpaceRocket.GetHorizontalDistanceTo(TargetPlayer);
			float InterpSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1000.f), FVector2D(MaxRotationSpeed, MinRotationSpeed), DistanceToPlayer);
			FRotator CurrentRotation = FMath::RInterpTo(SpaceRocket.ActorRotation, TargetRotation, DeltaTime, InterpSpeed);

			SpaceRocket.CurrentMovementSpeed += 100 * DeltaTime;

			SpaceRocket.AddActorWorldOffset(SpaceRocket.ActorForwardVector * SpaceRocket.CurrentMovementSpeed * DeltaTime);
			SpaceRocket.SetActorRotation(CurrentRotation);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Homing");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			MoveComp.Move(MoveData);

			FRotator TargetRot = ConsumedParams.Rotation;
			SpaceRocket.SetActorRotation(TargetRot);
		}
	}
}