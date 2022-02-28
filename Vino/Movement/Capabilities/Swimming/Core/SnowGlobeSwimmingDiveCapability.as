import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.SnowGlobeStopSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingDiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::Dive);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USnowGlobeSwimmingComponent SwimComp; 

	bool bIsLandingInWater = false;
	bool bShouldDive = false;
	FVector ResultingLocation = FVector::ZeroVector;

	float LaunchSpeed = 1300.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (IsActive())
			return; 

		if (!WasActionStarted(ActionNames::MovementJump))
			return;

		if (!MoveComp.CanCalculateMovement())
			return;

		if(!MoveComp.IsGrounded())
			return;	

		if (IsActioning(n"ForceJump"))
			return;

		bIsLandingInWater = CheckIfLandingInWater();

		if (!bIsLandingInWater)
			return;

		bShouldDive = CheckIfOpenWater();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;

		if (bShouldDive)
			return EHazeNetworkActivation::ActivateLocal;	

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{			
		bShouldDive = false;
		Player.SetCapabilityAttributeVector(n"DiveVelocity", GetLaunchVelocity());
		Player.SetCapabilityActionState(n"AllowDive", EHazeActionState::Active);
	}

	bool CheckIfLandingInWater()
	{
		FTrajectoryPoints Trajectory = CalculateTrajectory(Player.ActorLocation, 10000.f, GetLaunchVelocity(), 3000.f, 1.f);
		
		for (int Index = 0, Count = Trajectory.Positions.Num() - 1; Index < Count; ++Index)
		{
			FVector CurrentPoint = Trajectory.Positions[Index];
			FVector NextPoint = Trajectory.Positions[Index + 1];

			TArray<AActor> ActorsToIgnore;
			TArray<FHitResult> Hits;

			EDrawDebugTrace DrawDebugTrace = IsDebugActive() ? EDrawDebugTrace::ForDuration : EDrawDebugTrace::None;
			System::LineTraceMultiByProfile(CurrentPoint, NextPoint, n"PlayerCharacter", false, ActorsToIgnore, DrawDebugTrace, Hits, true, DrawTime = 2.f);	

			for (FHitResult Hit : Hits)
			{
				if (Hit.bBlockingHit)
				{
					// You hit something solid - don't dive
					return false;
				}
				else if (Cast<ASnowGlobeStopSwimmingVolume>(Hit.Actor) != nullptr)
				{
					// You hit a stop volume - Disregard all valid Swimming Volumes this trace

					bool bBlockingHit = false;
					// You hit a swimming volume - Make sure you didn't also hit a wall, or Stop Swimming Volume
					for (FHitResult SwimHit : Hits)
					{
						if (SwimHit.bBlockingHit)
							bBlockingHit = true;
					}

					if (bBlockingHit)
						return false;

					break;
				}
				else if (Cast<ASnowGlobeSwimmingVolume>(Hit.Actor) != nullptr)
				{
					bool bBlockingHit = false;
					bool bOverlappedStopVol = false;					

					// You hit a swimming volume - Make sure you didn't also hit a wall, or Stop Swimming Volume
					for (FHitResult SwimHit : Hits)
					{						
						// You hit a wall - Return to jail, do not pass go
						if (SwimHit.bBlockingHit)
							bBlockingHit = true;

						// You hit a Stop Swimming Volume - Invalid overlap, try again next trace
						if (Cast<ASnowGlobeStopSwimmingVolume>(SwimHit.Actor) != nullptr)
							bOverlappedStopVol = true;
					}

					if (bBlockingHit)
						return false;
					if (bOverlappedStopVol)
						break;

					ResultingLocation = Hit.Location;
					System::DrawDebugLine(ResultingLocation + FVector(0.f, 0.f, 150.f), ResultingLocation, Duration = 5.f);
					return true;
				}
			}
		}

		return false;
	}

	bool CheckIfOpenWater()
	{
		

		return true;
	}

	FVector GetLaunchVelocity() const
	{
		// Set horizontal velocity
		FVector Velocity = GetAttributeVector(AttributeVectorNames::MovementDirection);
		Velocity += FVector::UpVector * 1.3f;
		Velocity *= LaunchSpeed;
		Velocity *= FMath::Lerp(0.5f, 1.f, GetAttributeVector(AttributeVectorNames::MovementDirection).Size());		

		return Velocity; 
	}
	
}