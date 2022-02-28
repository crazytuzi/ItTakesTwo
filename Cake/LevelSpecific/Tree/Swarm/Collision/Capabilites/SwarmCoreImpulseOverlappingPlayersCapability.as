
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageResponseCapability;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Components.MovementComponent;

UCLASS(abstract)
class USwarmCoreImpulseOverlappingPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCollision");
	default CapabilityTags.Add(n"SwarmCollisionPlayer");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ASwarmActor SwarmActor = nullptr;

	UPROPERTY(Category = "Swarm Attack")
	UMovementSettings SkyDiveMovementSettings;

	USwarmBehaviourSettings Settings = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		Settings = USwarmBehaviourSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// SetMutuallyExclusive(n"SwarmCollisionPlayer", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bImpulseApplied_May)
		{
			Game::GetMay().UnblockCapabilities(n"TreeBoat", this);
			Game::GetMay().ClearSettingsWithAsset(SkyDiveMovementSettings, this);
		}

		if(bImpulseApplied_Cody)
		{
			Game::GetCody().UnblockCapabilities(n"TreeBoat", this);
			Game::GetCody().ClearSettingsWithAsset(SkyDiveMovementSettings, this);
		}

		// SetMutuallyExclusive(n"SwarmCollisionPlayer", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		 MakeOverlappingPlayerFly(DeltaTime);
	}

	bool bImpulseApplied_May = false;
	bool bImpulseApplied_Cody = false;

	void MakeOverlappingPlayerFly(const float DeltaSeconds)
	{
		const auto Cody = Game::GetCody();
		const auto May = Game::GetMay();

		// PrintToScreen("Impulse applied (Cody): " + bImpulseApplied_Cody);
		// PrintToScreen("Impulse applied (May): " + bImpulseApplied_May);

		if(bImpulseApplied_Cody)
		{
			UHazeMovementComponent MoveComp_Cody = UHazeMovementComponent::Get(Cody);
			if(MoveComp_Cody.IsGrounded())
			{
				Cody.ClearSettingsWithAsset(SkyDiveMovementSettings, this);
				bImpulseApplied_Cody = false;

				Cody.UnblockCapabilities(n"TreeBoat", this);
			}
		}

		if(bImpulseApplied_May)
		{
			UHazeMovementComponent MoveComp_May = UHazeMovementComponent::Get(May);
			if(MoveComp_May.IsGrounded())
			{
				May.ClearSettingsWithAsset(SkyDiveMovementSettings, this);
				bImpulseApplied_May = false;

				May.UnblockCapabilities(n"TreeBoat", this);
			}
		}

		if(bImpulseApplied_May && bImpulseApplied_Cody)
			return;

		TArray<AHazePlayerCharacter> OverlappedPlayers;
		if(SwarmActor.FindPlayersIntersectingSwarmBones(OverlappedPlayers) == false)
			return;

		// Push overlap notification to players
		for(int i = OverlappedPlayers.Num() - 1; i >= 0; --i)
		{
			UHazeMovementComponent PlayerMoveComp = UHazeMovementComponent::Get(OverlappedPlayers[i]);

			if(OverlappedPlayers[i] == May)
			{
				if(bImpulseApplied_May == false)
					bImpulseApplied_May = true;
				else
					continue;
			}

			if(OverlappedPlayers[i] == Cody)
			{
				if(bImpulseApplied_Cody == false)
					bImpulseApplied_Cody = true;
				else
					continue;
			}

			OverlappedPlayers[i].ApplySettings(
				SkyDiveMovementSettings,
				this,
				EHazeSettingsPriority::Script
			);

			FVector Impulse = FVector::UpVector * Settings.HitAndRun.Attack.ImpulseMagnitude;
			FHitResult GroundData = PlayerMoveComp.GetLastValidGround();
			FVector BoatVelocity = GroundData.GetComponent().GetPhysicsLinearVelocity();

			/////////////////////////////////////////////////

			float Height = 0.f;
			float Gravity = PlayerMoveComp.GetGravityMagnitude();
			float Velocity = Settings.HitAndRun.Attack.ImpulseMagnitude;
			float TerminalSpeed = PlayerMoveComp.MaxFallSpeed;

			float ValueToSqrt = ((-Height * 2.f) / Gravity + FMath::Square(Velocity / Gravity));
			if (ValueToSqrt < 0.f)
			{
				ensure(false);
				continue;
			}

			float TimeUntilWeLand = Velocity / Gravity + FMath::Sqrt(ValueToSqrt);

			if(TerminalSpeed > 0.f)
			{
				float TimeToReachTerminal = -((-TerminalSpeed) - Velocity);
				TimeToReachTerminal = TimeToReachTerminal / Gravity;

				// We'll reach terminal before landing!
				if (TimeToReachTerminal < TimeUntilWeLand)
				{
					// Height on trajectory when terminal is reached
					float TerminalHeight = TrajectoryFunction(TimeToReachTerminal, Gravity, Velocity);
					float TimeToFall = TerminalHeight / TerminalSpeed;
					TimeUntilWeLand = TimeToReachTerminal + TimeToFall;
				}
			}

			/////////////////////////////////////////////////

			// Print("TimeUntilWeLand: " + TimeUntilWeLand);

			// Impulse += (BoatVelocity * TimeUntilWeLand);
			Impulse += BoatVelocity;

			OverlappedPlayers[i].BlockCapabilities(n"TreeBoat", this);

			// Print("Adding IMpulse: "+ Impulse.Size());
			PlayerMoveComp.AddImpulse(Impulse);

			SwarmActor.VictimComp.OnVictimHitBySwarm.Broadcast(OverlappedPlayers[i]);

		}
	}
}


