import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseElectricity;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;

class UMicrophoneChaseVelocityPredictionComponent : UActorComponent
{
	bool ShouldPredictVelocity() const
	{
		return PredictionCounter <= 0;
	}

	void EnableVelocityPrediction()
	{
		PredictionCounter--;
	}

	void DisableVelocityPrediction()
	{
		PredictionCounter++;
	}

	private int PredictionCounter = 0;
}

class UMicrophoneChaseCrumbVelocityPredictionCalculator : UHazeReplicationLocationCalculator
{
	AHazePlayerCharacter Player;

	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;
	UUserGrindComponent GrindComp;
	USceneComponent RelativeComponent;
	UMicrophoneChaseVelocityPredictionComponent VelPredComp;
	UCharacterSlidingComponent SlidingComp;

	FVector LastVelocity;
	FVector VelocityOffsetCurrent;
	FVector LastLocation;

	TArray<AActor> ActorsToIgnore;

	float HitWall = 0.0f;
	float NoGround = 0.0f;
	float TimeSinceLastCrumb = 0.0f;

	bool bIsAirborne = false;
	bool bIsGrinding = false;
	bool bIsSliding = false;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		VelPredComp = UMicrophoneChaseVelocityPredictionComponent::GetOrCreate(Owner);
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
		RelativeComponent = InRelativeComponent;
		Reset();

		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{
		Reset();
	}

	private void Reset()
	{
		LastVelocity = VelocityOffsetCurrent = FVector::ZeroVector;
		bIsAirborne = bIsGrinding = bIsSliding = false;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		float IsAirborne = MoveComp.IsAirborne() ? 1.0f : 0.0f;
		float IsGrinding = GrindComp.HasActiveGrindSpline() ? 1.0f : 0.0f;
		float IsSliding = SlidingComp.bIsSliding ? 1.0f : 0.0f;
		OutTargetParams.CustomLocation = FVector(IsAirborne, IsGrinding, IsSliding);
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		const FVector ScaledVelocity = TargetParams.Velocity * (CrumbComp.PredictionLag + TimeSinceLastCrumb);
		TimeSinceLastCrumb = 0.0f;
		LastVelocity = ScaledVelocity;
		bIsAirborne = TargetParams.CustomLocation.X > 0.0f;
		bIsGrinding = TargetParams.CustomLocation.Y > 0.0f;
		bIsSliding = TargetParams.CustomLocation.Z > 0.0f;

		FHitResult Hit;
		const FVector StartLocation = TargetParams.Location;
		const FVector EndLocation = TargetParams.Location + ScaledVelocity;

		if(!bIsAirborne)
		{
			Hit.Reset();
			System::LineTraceSingle(EndLocation, EndLocation - FVector(0, 0, 200), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);
			if(!Hit.bBlockingHit)
			{
				NoGround = 0.8f;
			}
		}
	}

	FVector GetVelocityOffsetTarget() const property
	{
		if(bIsGrinding)
			return FVector::ZeroVector;

		if(!VelPredComp.ShouldPredictVelocity())
			return FVector::ZeroVector;

		if(NoGround > 0.0f)
			return FVector::ZeroVector;

		return LastVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		FVector InvalidLocationDirection = FVector::ZeroVector;

		FHitResult Hit;
		const float HalfHeight = Player.CapsuleComponent.CapsuleHalfHeight;
		const FVector HeightOffset = FVector(0, 0, HalfHeight);
		FVector StartLocation = TargetParams.Location + HeightOffset;

		FVector PredictionDirection = FVector::ZeroVector;

		if(bIsSliding)
			PredictionDirection = VelocityOffsetCurrent;
		else 
			PredictionDirection = (VelocityOffsetCurrent.GetSafeNormal2D() * VelocityOffsetCurrent.Size());

		FVector EndLocation = StartLocation + PredictionDirection;

		if(!bIsGrinding)
		{
			System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);
			
			if(Hit.bBlockingHit)
			{
				InvalidLocationDirection = (EndLocation - StartLocation).GetSafeNormal() * ((EndLocation - StartLocation).Size() - Hit.Distance);
			}

			if(!bIsAirborne)
			{
				EndLocation -= InvalidLocationDirection;

				Hit.Reset();
				System::LineTraceSingle(EndLocation, EndLocation - FVector(0, 0, 200), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

				if(!Hit.bBlockingHit)
				{
					const FVector DirectionToLastLocation = (LastLocation - EndLocation);
					InvalidLocationDirection -= DirectionToLastLocation;
				}
			}
		}

		const FVector ModifiedVelocityOffset = VelocityOffsetCurrent - InvalidLocationDirection;
		const float HeightPrediction = bIsSliding ? ModifiedVelocityOffset.Z : 0.0f;
		const FVector FinalVelocityOffsetModifier = FVector(ModifiedVelocityOffset.X, ModifiedVelocityOffset.Y, HeightPrediction);

		TargetParams.Location = TargetParams.Location + FinalVelocityOffsetModifier;
		
		if(FinalVelocityOffsetModifier.SizeSquared() > 0.0f && !bIsGrinding)
			TargetParams.Rotation = FinalVelocityOffsetModifier.GetSafeNormal2D().Rotation();
	}

	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
		VelocityOffsetCurrent = FMath::VInterpTo(VelocityOffsetCurrent, VelocityOffsetTarget, DeltaTime, InterpSpeed);

		
		TimeSinceLastCrumb += DeltaTime;
		HitWall -= DeltaTime;
		NoGround -= DeltaTime;
		LastLocation = CurrentParams.Location;
	}

	private bool IsMoving(FVector Velocity) const
	{
		return Velocity.SizeSquared2D() > 1.0f;
	}

	float GetInterpSpeed() const property
	{
		if(HitWall > 0.0f)
			return 10.0f;

		if(NoGround > 0.0f)
			return 5.0f;

		return 3.0f;
	}
}

class UMicrophoneChaseCrumbVelocityPredictionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"MicrophoneChase";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	UHazeCrumbComponent CrumbComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(UMicrophoneChaseCrumbVelocityPredictionCalculator::StaticClass(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComp.RemoveCustomWorldCalculator(this);
	}
}
