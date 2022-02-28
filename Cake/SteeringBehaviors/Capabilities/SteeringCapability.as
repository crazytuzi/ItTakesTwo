import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdSettings;

class USteeringCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SteeringBehavior");
	default CapabilityTags.Add(n"SteeringBehaviorMovement");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AKeyBird KeyBird;
	UHazeCrumbComponent CrumbComp;
	USteeringBehaviorComponent Steering;
	UKeyBirdSettings Settings;

	FVector CurrentSteeringDirection;

	float CurrentVelocity = 0.0f;
	float CurrentRoll = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentSteeringDirection = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat FacingRotation;
		CalculateFrameMove(FacingRotation, DeltaTime);
		KeyBird.MeshOffset.SetWorldRotation(FacingRotation);
	}

	void CalculateFrameMove(FQuat& NewFacingRotation, float DeltaTime)
	{
		if(HasControl())
		{
			float Dot = FMath::GetMappedRangeValueClamped(FVector2D(-1.0f, 1.0f), FVector2D(0.9f, 1.1f), CurrentSteeringDirection.DotProduct(Steering.DirectionToTarget));
			float DragMul = FMath::GetMappedRangeValueClamped(FVector2D(-1.0f, 1.0f), FVector2D(1.6f, 1.0f), CurrentSteeringDirection.DotProduct(Steering.DirectionToTarget));
			CurrentSteeringDirection = FMath::QInterpTo(CurrentSteeringDirection.ToOrientationQuat(), Steering.DirectionToTarget.ToOrientationQuat(), DeltaTime, Settings.TurnRate * Dot).Vector();
			
			float YawTurn = FMath::Clamp(FMath::FindDeltaAngleRadians(CurrentSteeringDirection.X, Steering.DirectionToTarget.X), -1.0f, 1.0f);

			// Slow down when starting to reach the target location.
			const float DistanceMinimum = 2500.0f;
			const float DistanceToLocation = Steering.Seek.SeekLocation.Distance(Steering.WorldLocation);
			const float DistanceMultiplier = FMath::Clamp(DistanceToLocation / DistanceMinimum, 0.7f, 1.0f);
			
			CurrentVelocity -= CurrentVelocity * (Settings.Drag * DragMul) * DeltaTime;
			CurrentVelocity = FMath::Min(CurrentVelocity + Settings.Acceleration * DeltaTime, Settings.VelocityMaximum * DistanceMultiplier);

			const float RollTurnRate = 80.0f;
			CurrentRoll = FMath::FInterpConstantTo(CurrentRoll, RollTurnRate * YawTurn, DeltaTime, 50.0f);

			KeyBird.MeshBody.RelativeRotation = FRotator(0.0f, 0.0f, CurrentRoll);

			/*if(KeyBird.CurrentVelocity.Size() > Settings.VelocityMaximum)
			{
				KeyBird.CurrentVelocity = KeyBird.CurrentVelocity.GetSafeNormal() * KeyBird.VelocityMaximum;
			}*/
			
			Steering.Velocity = KeyBird.CurrentVelocity;
			Steering.VelocityMagnitude = CurrentVelocity;

			Owner.AddActorWorldOffset(CurrentSteeringDirection * CurrentVelocity * DeltaTime);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			CurrentSteeringDirection = FMath::VInterpNormalRotationTo(CurrentSteeringDirection, ConsumedParams.DeltaTranslation.GetSafeNormal(), DeltaTime, 100.0f);
			Owner.SetActorLocation(ConsumedParams.Location);
		}

		NewFacingRotation = CurrentSteeringDirection.ToOrientationQuat();
	}
}
