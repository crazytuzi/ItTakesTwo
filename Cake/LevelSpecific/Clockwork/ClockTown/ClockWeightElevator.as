import Vino.Pickups.PickupActor;
import Vino.Movement.MovementSystemTags;

event void FClockWeightElevatorEvent();

struct FWeightInBox
{
	TArray<AHazePlayerCharacter> PreviousGroundedPlayers;
	TArray<AHazePlayerCharacter> GroundedPlayers;
};

class AClockWeightElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = LeftElevatorRoot)
	UBoxComponent LeftWeightBox;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = RightElevatorRoot)
	UBoxComponent RightWeightBox;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	// Constant force that the elevator wants to go up by at all times
	UPROPERTY(Category = "Elevator Physics")
	float ConstantUpwardForce = 500.f;

	// Downward force applied by a player standing on one of the elevators
	UPROPERTY(Category = "Elevator Physics")
	float DownwardForcePerPlayer = 50.f;

	// Downward force applied by a pickup laying on one of the elevators (or in a player's hands on one of them)
	UPROPERTY(Category = "Elevator Physics")
	float DownwardForcePerPickup = 1500.f;

	// Force when a player lands on a platform
	UPROPERTY(Category = "Elevator Physics")
	float JumpLandImpulse = 200.f;

	// Force when a player ground pounds on a platform
	UPROPERTY(Category = "Elevator Physics")
	float GroundPoundImpulse = 450.f;

	UPROPERTY()
	FClockWeightElevatorEvent OnReachedTop;

	UPROPERTY()
	FClockWeightElevatorEvent OnMovingAgain;

	UPROPERTY()
	FClockWeightElevatorEvent OnReachedBottom;

	UPROPERTY()
	FClockWeightElevatorEvent OnMoving;

	private FHazeConstrainedPhysicsValue LiftHeight;
	default LiftHeight.Value = 0.f;
	default LiftHeight.LowerBound = 0.f;
	default LiftHeight.Friction = 1.2f;
	default LiftHeight.LowerBounciness = 0.3f;
	default LiftHeight.UpperBounciness = 0.3f;

	private FVector RightElevatorStart;
	private FVector LeftElevatorStart;

	private FWeightInBox LeftWeight;
	private FWeightInBox RightWeight;

	private float PrevLiftPosition = -1.f;

	bool bAtTop = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RightElevatorStart = RightElevatorRoot.RelativeLocation;
		LeftElevatorStart = LeftElevatorRoot.RelativeLocation;

		LiftHeight.UpperBound = LeftElevatorStart.Z - RightElevatorStart.Z;
	}

	void UpdateWeightInBox(UBoxComponent Box, FWeightInBox& Weight, float DeltaTime, float Direction)
	{
		TArray<AActor> Actors;
		Box.GetOverlappingActors(Actors);

		Weight.PreviousGroundedPlayers = Weight.GroundedPlayers;
		Weight.GroundedPlayers.Reset();

		// Add the normal downward force from anything on this elevator
		for (AActor Actor : Actors)
		{
			auto Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player != nullptr)
			{
				auto MoveComp = UHazeBaseMovementComponent::Get(Player);
				if (MoveComp.IsGrounded())
				{
					LiftHeight.AddAcceleration(DownwardForcePerPlayer * Direction);
					Weight.GroundedPlayers.Add(Player);
				}
			}

			auto Pickup = Cast<APickupActor>(Actor);
			if (Pickup != nullptr)
			{
				if (Pickup.IsPickedUp())
				{
					auto HoldingPlayer = Pickup.HoldingPlayer;
					auto MoveComp = UHazeBaseMovementComponent::Get(HoldingPlayer);
					if (MoveComp.IsGrounded())
						LiftHeight.AddAcceleration(DownwardForcePerPickup * Direction);
				}
				else
				{
					LiftHeight.AddAcceleration(DownwardForcePerPickup * Direction);
				}
			}
		}

		// Add a 'landed' bounce from players that have landed on the elevator
		for (auto Player : Weight.GroundedPlayers)
		{
			if (!Weight.PreviousGroundedPlayers.Contains(Player))
			{
				if (Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
					LiftHeight.AddImpulse(GroundPoundImpulse * Direction);
				else
					LiftHeight.AddImpulse(JumpLandImpulse * Direction);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAtTop)
			return;

		// Update the internal physics simulation for the lift
		LiftHeight.AddAcceleration(ConstantUpwardForce);
		UpdateWeightInBox(LeftWeightBox, LeftWeight, DeltaTime, 1.f);
		UpdateWeightInBox(RightWeightBox, RightWeight, DeltaTime, -1.f);

		LiftHeight.Update(DeltaTime);

		if (PrevLiftPosition == LiftHeight.Value)
		{
			OnReachedBottom.Broadcast();
		}

		// Position the lift at the right location
		if (PrevLiftPosition != LiftHeight.Value)
		{
			RightElevatorRoot.RelativeLocation = RightElevatorStart + FVector(0.f, 0.f, LiftHeight.Value);
			LeftElevatorRoot.RelativeLocation = LeftElevatorStart - FVector(0.f, 0.f, LiftHeight.Value);
			PrevLiftPosition = LiftHeight.Value;

			OnMoving.Broadcast();
		}

		if (LiftHeight.HasHitUpperBound())
		{
			bAtTop = true;
			System::SetTimer(this, n"StartMovingAgain", 0.75f, false);
			OnReachedTop.Broadcast();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartMovingAgain()
	{
		OnMovingAgain.Broadcast();
		bAtTop = false;
	}
};