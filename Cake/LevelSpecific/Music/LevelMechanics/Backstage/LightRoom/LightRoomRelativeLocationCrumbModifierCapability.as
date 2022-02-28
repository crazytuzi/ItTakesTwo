import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightCharacterComponent;

class ULightRoomRelativeLocationCrumbModifierCalculator : UHazeReplicationLocationCalculator
{
	AHazePlayerCharacter Player;
	ULightRoomSpotlightCharacterComponent SpotlightComp;

	TArray<AActor> IgnoreActors;
	FVector TargetLocation;
	FVector PreviousLocation;
	FVector LastPlayerLocation;

	float StandingStillTime = 0.0f;

	bool bIsMoving = false;
	bool bIsOnGround = true;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		IgnoreActors.Add(Player);
		SpotlightComp = ULightRoomSpotlightCharacterComponent::Get(Owner);
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{
		Reset();
	}

	private void Reset()
	{
		LastPlayerLocation = TargetLocation = PreviousLocation = Player.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.Location = Player.ActorLocation;
		OutTargetParams.CustomLocation = RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		bIsMoving = IsMoving(FromParams.Velocity, FromParams.Location);

		if(bIsMoving)
		{
			FVector DirectionToControlSpotlight2D = (RelativeLocation - TargetParams.Location).GetSafeNormal2D();
			FVector VelocityDir2D = TargetParams.Velocity.GetSafeNormal2D();
			float SpotlightDot = FMath::Max(VelocityDir2D.DotProduct(DirectionToControlSpotlight2D), 0.0f);
			FVector ToSpotlight = TargetParams.Location - RelativeLocation;
			TargetLocation = TargetParams.Location + (VelocityDir2D * ToSpotlight.Size()) * SpotlightDot;
			StandingStillTime = 0;
		}
		else
		{
			TargetLocation = TargetParams.Location;
		}

		bIsOnGround = IsLocationOnGround(TargetLocation);

		if(!bIsOnGround)
		{
			TargetLocation = TargetParams.Location;
		}

		PreviousLocation = TargetLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		TargetParams.Location = LastPlayerLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{

		const float DistanceAlpha = FMath::Min(LastPlayerLocation.Distance(TargetLocation) / 650.f, 1.f);
		const float MovementSpeed = Player.GetMovementState().MoveSpeed;
		if(bIsMoving)
		{
			float LerpValue = FMath::Lerp(CurrentParams.Velocity.Size(), MovementSpeed * 1.5f, DistanceAlpha);
			LastPlayerLocation = FMath::VInterpConstantTo(LastPlayerLocation, TargetLocation, DeltaTime, LerpValue);
		}
		else
		{
			float Alpha = FMath::Clamp(StandingStillTime - 0.5f, 0.f, 1.f);
			StandingStillTime += DeltaTime;
			LastPlayerLocation = FMath::VInterpConstantTo(LastPlayerLocation, TargetLocation, DeltaTime, FMath::Lerp(0.f, MovementSpeed, FMath::EaseIn(0.f, 1.f, Alpha, 2.f)));
		}
	}

	bool IsMoving(FVector Velocity, FVector LocationToTest) const
	{
		return Velocity.SizeSquared2D() > 1.0f;
	}

	bool IsLocationOnGround(FVector LocationToTest) const
	{
		FHitResult Hit;
		System::LineTraceSingle(LocationToTest, LocationToTest - FVector::UpVector * 1000.0f, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		return Hit.bBlockingHit;
	}

	FVector GetRelativeLocation() const property
	{
		float DistanceMinSq = Math::GetMaxFloat();
		AHazeActor Closest;
		FVector RelativeLoc;

		for (auto LocActor : SpotlightComp.SpotlightLocationActors)
		{
			if(!LocActor.bIsProvidingLight)
				continue;

			const float DistanceSq = LocActor.ActorLocation.DistSquared2D(Player.ActorLocation);
				

			if(DistanceSq < DistanceMinSq)
			{
				Closest = LocActor;
				DistanceMinSq = DistanceSq;
			}
		}

		if(Closest == nullptr)
			return FVector::ZeroVector;

		return Closest.ActorLocation;
	}
}

class ULightRoomRelativeLocationCrumbModifierCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default CapabilityTags.Add(n"LightRoom");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	UHazeCrumbComponent CrumbComp;
	ULightRoomSpotlightCharacterComponent SpotlightComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SpotlightComp = ULightRoomSpotlightCharacterComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SpotlightComp.bLightRoomDeathEnabled)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SpotlightComp.bLightRoomDeathEnabled)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(ULightRoomRelativeLocationCrumbModifierCalculator::StaticClass(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComp.RemoveCustomWorldCalculator(this);
	}
}
