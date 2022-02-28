
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageResponseCapability;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Cake.LevelSpecific.Tree.Swarm.Collision.Capabilites.SwarmRailSwordImpulseSlowmotionCapability;

class USwarmRailSwordImpulseGrindingPlayers : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCollision");
	default CapabilityTags.Add(n"SwarmCollisionPlayer");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// before the default HandlePlayerCollisionCapability
	default TickGroupOrder = 99;

	ASwarmActor SwarmActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
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
		SetMutuallyExclusive(n"SwarmCollisionPlayer", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"SwarmCollisionPlayer", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		MakeOverlappingPlayerFly(DeltaTime);
	}

	void MakeOverlappingPlayerFly(const float DeltaSeconds)
	{
		const AHazePlayerCharacter May = Game::GetMay();
		const AHazePlayerCharacter Cody = Game::GetCody();
		const auto ResponseComp_May = USwarmRailSwordImpulsePlayerResponseComponent::GetOrCreate(May);
		const auto ResponseComp_Cody = USwarmRailSwordImpulsePlayerResponseComponent::GetOrCreate(Cody);
		const bool bCanDamage_May = ResponseComp_May.CanDamagePlayer(); 
		const bool bCanDamage_Cody = ResponseComp_Cody.CanDamagePlayer();

		if(bCanDamage_Cody == false && bCanDamage_May == false)
			return;

		TArray<AHazePlayerCharacter> OverlappedPlayers;
		if(SwarmActor.FindPlayersIntersectingSwarmBones(OverlappedPlayers) == false)
			return;

		// Push overlap notification to players
		for(int i = OverlappedPlayers.Num() - 1; i >= 0; --i)
		{
			if(OverlappedPlayers[i].IsMay() && bCanDamage_May == false)
				continue;

			if(OverlappedPlayers[i].IsCody() && bCanDamage_Cody == false)
				continue;

			OverlappedPlayers[i].SetCapabilityActionState(n"SwarmRailImpulse", EHazeActionState::ActiveForOneFrame);
		}
	}
}