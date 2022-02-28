
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class USwarmCoreUpdateClosestPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCoreUpdateClosestPlayer");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	float TimeStampUpdate = 0.f;

	ASwarmActor Swarm = nullptr;
	USwarmVictimComponent VictimComp = nullptr;
	UPlayerHealthComponent VictimHPComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
		VictimComp = Swarm.VictimComp;
		VictimHPComp = UPlayerHealthComponent::Get(Swarm.VictimComp.CurrentVictim);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{

#if TEST
		ensure((VictimHPComp != nullptr) == (VictimComp.CurrentVictim != nullptr));
#endif TEST

//		if(AreBothPlayersDead())
// 			return EHazeNetworkActivation::DontActivate;

		// force update when the victim dies
		if(VictimHPComp != nullptr && VictimHPComp.bIsDead)
			return EHazeNetworkActivation::ActivateFromControl;

		if(VictimComp.IsVictimOverrideRequested())
		{
			if (VictimComp.ShouldApplyVictimOverride())
			{
				return EHazeNetworkActivation::ActivateFromControl;
			}
		}
		else if(VictimComp.CurrentVictim == nullptr)
		{
			const float TimeSinceUpdate = Time::GetGameTimeSince(TimeStampUpdate);
			if(TimeSinceUpdate >= VictimComp.TimebetweenUpdates)
			{
				return EHazeNetworkActivation::ActivateFromControl;
			}
		}

 		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{

#if TEST
		// We can't send the network messages to often!
		ensure(VictimComp.TimebetweenUpdates >= 0.1f);
#endif TEST

		// prevent spam
		const float TimeSinceUpdate = Time::GetGameTimeSince(TimeStampUpdate);
		if(TimeSinceUpdate <= VictimComp.TimebetweenUpdates)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		FSwarmOverrideClosestPlayer PlayerOverrideData;

		if (VictimComp.ClosestPlayerOverrides.Num() != 0)
			PlayerOverrideData = VictimComp.ClosestPlayerOverrides.Last();
		else 
			PlayerOverrideData.Player = VictimComp.FindClosestLivingPlayerWithinRange();

		// both players are dead?
		if (PlayerOverrideData.Player == nullptr)
			return;

		auto HealthComp = UPlayerHealthComponent::Get(PlayerOverrideData.Player); 
		if(HealthComp.bIsDead)
		{
			auto OtherPlayer = PlayerOverrideData.Player.OtherPlayer;
			HealthComp = UPlayerHealthComponent::Get(OtherPlayer); 
			if(HealthComp.bIsDead)
			{
				// both players are dead
				return;
			}
			else
			{
				// this is OK even in the case of Gentleman. The Swarm will fallback on behaviour 
				// capabilities that doesn't check for IsClaiming() and work its way back up again
				PlayerOverrideData = FSwarmOverrideClosestPlayer();
				PlayerOverrideData.Player = OtherPlayer;
			}
		}

		// Not sending this will trigger a reset below
		OutParams.AddStruct(n"PlayerOverrideData", PlayerOverrideData);
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		FSwarmOverrideClosestPlayer PlayerOverrideData;
		ActivationParams.GetStruct(n"PlayerOverrideData", PlayerOverrideData);

		// set new data, regardless if it is valid or not.
		VictimComp.CurrentVictim = PlayerOverrideData.Player;
//		VictimComp.CurrentOverride = PlayerOverrideData;

		TimeStampUpdate = Time::GetGameTimeSeconds();

		if(PlayerOverrideData.Player != nullptr)
		{
			VictimHPComp = UPlayerHealthComponent::Get(PlayerOverrideData.Player);

			// we add ourselves to the opponent array due to us having 
			// swarm formations. Having a claim isn't required. (unique is needed)
			USwarmGentlemanComponent VictimGentlemanComp = USwarmGentlemanComponent::GetOrCreate(PlayerOverrideData.Player);
			VictimGentlemanComp.Opponents.AddUnique(Swarm);

			// remove from previous
			USwarmGentlemanComponent OtherGentlemanComp = USwarmGentlemanComponent::GetOrCreate(PlayerOverrideData.Player.OtherPlayer);
			OtherGentlemanComp.Opponents.RemoveSwap(Swarm);

			// we'll have to crumb everything for this work nicely?
			// Swarm.SetControlSide(PlayerOverrideData.Player);
		}
		else
		{
			// Make sure that THIS capability doesn't do 
			// another forceUpdate because the player is dead.
			VictimHPComp = nullptr;

			// remove from both player since we don't have any victim
			AHazePlayerCharacter May, Cody;
			Game::GetMayCody(May, Cody);
			auto GentlemanComp_May = USwarmGentlemanComponent::GetOrCreate(May);
			auto GentlemanComp_Cody = USwarmGentlemanComponent::GetOrCreate(Cody);
			GentlemanComp_May.Opponents.Remove(Swarm);
			GentlemanComp_Cody.Opponents.Remove(Swarm);
		}

 	}

	bool AreBothPlayersDead() const
	{
		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		const UPlayerHealthComponent MayHPComp = UPlayerHealthComponent::Get(May);
		const UPlayerHealthComponent CodyHPComp = UPlayerHealthComponent::Get(Cody);

		// both are dead
		if (MayHPComp == nullptr && CodyHPComp == nullptr)
			return true;

		// only one of them are dead
		if (MayHPComp == nullptr || CodyHPComp == nullptr)
			return false;

		return MayHPComp.bIsDead && CodyHPComp.bIsDead;
	}

}
