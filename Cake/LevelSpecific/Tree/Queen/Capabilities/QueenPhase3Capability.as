import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackSwords;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.Phase3RailSwordComponent;
import Cake.Weapons.Match.MatchWeaponStatics;
import Cake.Weapons.Sap.SapWeaponStatics;

UCLASS()
class UQueenPhase3Capability : UQueenBaseCapability 
{
	int CurrentSwarmCount = 0;
	UQueenSpecialAttackSwords Manager = nullptr;
	TArray<ASwarmActor> PendingSwarms;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Manager = UQueenSpecialAttackSwords::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.QueenPhase == EQueenPhaseEnum::Phase3)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.QueenPhase != EQueenPhaseEnum::Phase3)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// needed in order to release the intro swords. This event is networked on the queens actor channel
		Queen.OnArmourTakenDamage.AddUFunction(this, n"HandleArmorTakenDamage");

		// Add a network sync point here because the broadcast for these events 
		// originate from actor channels that don't belong to the queen. Ideally we'd do this elsewhere, 
		// and one can perhaps also question if this is even needed. But bugs which are hard to reproduce
		// keep triggering for QA late in production. This is quick fix so that we can move on.
		if (HasControl())
		{
			Queen.BehaviourComp.OnSwarmSpawned.AddUFunction(this, n"HandleSwarmSpawned");
			Queen.ParkingSpotComp.OnSwarmParked.AddUFunction(this, n"HandleSwarmParked");
			Queen.ParkingSpotComp.OnSwarmUnparked.AddUFunction(this, n"HandleSwarmUnparked");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (HasControl())
		{
			Queen.BehaviourComp.OnSwarmSpawned.Unbind(this, n"HandleSwarmSpawned");
			Queen.ParkingSpotComp.OnSwarmParked.Unbind(this, n"HandleSwarmParked");
			Queen.ParkingSpotComp.OnSwarmUnparked.Unbind(this, n"HandleSwarmUnparked");
		}

		// needed in order to release the intro swords. This event is networked on the queens actor channel
		Queen.OnArmourTakenDamage.Unbind(this, n"HandleArmorTakenDamage");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float Dt)
	{
		if (HasControl())
		{
			if(Manager.MasterShield != nullptr)
				Manager.AssignVictimForMasterShield();

			UpdateSwarmShapes();
		}

		Manager.UpdateDesiredAngles();

		UpdatePointOfInterests();

		// DebugLists();
		// DebugDrawSwarmLocations();
	}

	void UpdatePointOfInterests()
	{
		for (AHazePlayerCharacter IterPlayer : Game::Players)
			UpdatePointOfInterestForPlayer(IterPlayer);
	}

	void UpdatePointOfInterestForPlayer(AHazePlayerCharacter InPlayer)
	{
		const bool bAiming = InPlayer.IsMay() ? IsAimingWithMatchWeapon() : IsAimingWithSapWeapon();
		const bool bPOIActivity = IsHookPOIActive(InPlayer);

//		PrintToScreen("Hook POI applied to " + InPlayer.GetName(), 0.f, bPOIActivity ? FLinearColor::Green : FLinearColor::Red);

		if(bAiming && IsHookWithinView(InPlayer))
		{
			if(!bPOIActivity)
			{
				ApplyHookPOI(InPlayer);
			}
		}
		else if(bPOIActivity)
		{
			InPlayer.ClearPointOfInterestByInstigator(this);
		}
	}

	bool IsHookWithinView(AHazePlayerCharacter InPlayer) const
	{
		const FVector2D WithinFraction = FVector2D(0.3, 0.7f);
		return SceneView::IsInView(InPlayer, Queen.Mesh.GetSocketLocation(n"Base"), WithinFraction, WithinFraction);
	}

	bool IsHookPOIActive(AHazePlayerCharacter InPlayer) const
	{
		auto CameraUser = UHazeActiveCameraUserComponent::Get(InPlayer);
		auto FocusTargetActor = CameraUser.GetPointOfInterest().PointOfInterest.FocusTarget.Actor;
		if(FocusTargetActor == Queen)
		{
			return true;
		}

		return false;
	}

	void ApplyHookPOI(AHazePlayerCharacter InPlayer)
	{
		FHazePointOfInterest POI = FHazePointOfInterest();
		POI.FocusTarget = FHazeFocusTarget();

		POI.FocusTarget.Actor = Queen;
		POI.FocusTarget.Component = Queen.Mesh;
		POI.FocusTarget.Socket = n"Base";

		POI.FocusTarget.ViewOffset = FVector::RightVector * -1100.f;
		POI.FocusTarget.ViewOffset += FVector::UpVector * -500.f;
		POI.Blend.BlendTime = 2.5f;

		// script because olsson refuses to add ::Higher :))
		// InPlayer.ApplyClampedPointOfInterest(POI, this, EHazeCameraPriority::Script);
		InPlayer.ApplyInputAssistPointOfInterest(POI, this, EHazeCameraPriority::Script);
	}

	UFUNCTION()
	void HandleArmorTakenDamage(FVector HitLocation, USceneComponent HitComponent, FName HitSocket, float DamageTaken)
	{
		// do-once: release the 3 intro swords when the final armor piece takes damage
		Manager.StartIntroSwordAttack();
		Queen.OnArmourTakenDamage.Unbind(this, n"HandleArmorTakenDamage");
	}

	UFUNCTION()
	void HandleSwarmDeath(ASwarmActor InSwarm)
	{
		devEnsure(HasControl(), "Remote entered a HandleSwarmDeath() when it shouldn't have. \n Please notify sydney");
		NetHandleSwarmDeath(InSwarm);
	}

	UFUNCTION()
	void HandleSwarmParked(ASwarmActor InSwarm)
	{
		devEnsure(HasControl(), "Remote entered a HandleSwarmParked() when it shouldn't have. \n Please notify sydney");
		NetHandleSwarmParked(InSwarm);
	}

	UFUNCTION()
	void HandleSwarmUnparked(ASwarmActor InSwarm)
	{
		devEnsure(HasControl(), "Remote entered a HandleSwarmUnparked() when it shouldn't have. \n Please notify sydney");
		NetAddSwarm(InSwarm);
	}
	
	UFUNCTION()
	void HandleSwarmSpawned(ASwarmActor InSwarm)
	{
		devEnsure(HasControl(), "Remote entered a HandleSwarmSpawned() when it shouldn't have. \n Please notify sydney");
		NetAddSwarm(InSwarm);
	}

	UFUNCTION(NetFunction)
	void NetAddSwarm(ASwarmActor InSwarm)
	{
		devEnsure(!PendingSwarms.Contains(InSwarm), "trying to add (spawned) swarm to 'pending swarm list' multiple times");
		devEnsure(!Manager.Swarms.Contains(InSwarm), "trying to add (spawned) swarm to Queen P3 Swarm-team multiple times");

		PendingSwarms.Add(InSwarm);
		ProcessPendingSwarms();
	}

	UFUNCTION(NetFunction)
	void NetHandleSwarmParked(ASwarmActor InSwarm)
	{
		RemoveSwarm(InSwarm);
	}

	UFUNCTION(NetFunction)
	void NetHandleSwarmDeath(ASwarmActor InSwarm)
	{
		RemoveSwarm(InSwarm);

		// do-once: release the 3 intro swords upon first swarm taking damage
		Manager.StartIntroSwordAttack();
	}

	void RemoveSwarm(ASwarmActor InSwarm)
	{
		PendingSwarms.Remove(InSwarm);
		Manager.RemoveSwarm(InSwarm);

		if(Manager.MasterShield == nullptr && HasControl())
			Manager.AssignMasterShield();

		if(HasControl())
		{
			InSwarm.OnAboutToDie.Unbind(this, n"HandleSwarmDeath");
		}
	}

	void ProcessPendingSwarms()
	{
		// Add new swarms once vacant spots that are available.
		// (vacant spots are flagged with nullptr)
		TArray<ASwarmActor> CleanedArray = Manager.Swarms;
		CleanedArray.RemoveAll(nullptr);
		while(PendingSwarms.Num() != 0 && CleanedArray.Num() < 4)
		{
			auto TempSwarm = PendingSwarms[0];
			AddSwarmToTeam(TempSwarm);
			PendingSwarms.RemoveSwap(TempSwarm);
			CleanedArray.Add(TempSwarm);
		}

		// they should've all be added in the while loop
		devEnsure(PendingSwarms.Num() == 0, "All Swarms were not added from the pending swarms array. \n please notify sydney");
	}

	void AddSwarmToTeam(ASwarmActor InSwarm)
	{
		devEnsure(!Manager.Swarms.Contains(InSwarm), "trying to add swarm to Queen P3 Swarm-team multiple times");

		AssignInitialShape(InSwarm);

		Manager.AddSwarm(InSwarm);

		if(HasControl())
		{
			// we use the swarm OnDie event directly because we need a death event 
			// which is isolated to P3, in order to handle the 3 intro swords. 
			// Swarms are killed/parked upon entering P3 which would trigger the
			// intro swords immediately. Not using the behaviourComponents OnDie event 
			// will be less error prone when making future changes.
			InSwarm.OnAboutToDie.AddUFunction(this, n"HandleSwarmDeath");
		}
	}

	void AssignInitialShape(ASwarmActor InSwarm)
	{
		// ignore intro swarms until they says they are ready to be managed
		auto ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(InSwarm);
		if (ManagedSwarmComp.bIntroSwarm)
			return;

		if(Manager.MasterShield == nullptr)
		{
			Manager.MasterShield = InSwarm;
			InSwarm.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);
			SwitchToShield(InSwarm);
		}
		else
		{
			// it has to be a shield atm. We'll have to 
			// rewrite how the swords keeps track of each 
			// other if we want a fresh swarm to directly 
			// go to sword, skipping shield. 
			SwitchToShield(InSwarm);
		}
	}

	void UpdateSwarmShapes()
	{
		// Only start the timer once the intro swarms are "done"
		// (which is when the swarms start placing themselves on the rail)
		if(AreIntroSwarmsActive())
			Manager.TimeStampShapeDuration = Time::GetGameTimeSeconds();

		const float TimeSinceShapeChange = Time::GetGameTimeSince(Manager.TimeStampShapeDuration);
		const bool bRailSwording = SwarmsAreRailSwording();
		const bool bShielding = SwarmsAreShielding();

		// PrintToScreen("TimeSinceShapeChange : " + TimeSinceShapeChange);
		// PrintToScreen("bShielding", 0.f, bShielding ? FLinearColor::Green : FLinearColor::Red);
		// PrintToScreen("bRailSwording", 0.f, bRailSwording ? FLinearColor::Green : FLinearColor::Red);

		if(bRailSwording)
		{
			// placing the if statement here, and not above, 
			// prevents newly spawned swarms from re-triggering a sword attack
			if(TimeSinceShapeChange > Manager.ShapeDuration_Swords)
				HandleChangeToShields();
		}
		else if(bShielding && TimeSinceShapeChange > Manager.ShapeDuration_Shields)
		{
			HandleChangeToRailSwords();
		}

	}

	void HandleChangeToShields()
	{
		TArray<int> SwarmIndicesThatWillChangeShape;
		SwarmIndicesThatWillChangeShape.Reserve(4);

		for(int i = 0; i < Manager.Swarms.Num(); ++i)
		{
			ASwarmActor& SwarmIter = Manager.Swarms[i];

			// nullptr means vacant spot.
			if (SwarmIter == nullptr)
				continue;

			// ignore intro swarms until they are done
			UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(SwarmIter);
			if(ManagedSwarmComp.bIntroSwarm)
				continue;

			if(SwarmIter == Manager.MasterShield)
				continue;

			SwarmIndicesThatWillChangeShape.Add(i);
		}

		if(SwarmIndicesThatWillChangeShape.Num() > 0)
		{
			NetOrderShieldFormation(SwarmIndicesThatWillChangeShape);
		}
	}

	void HandleChangeToRailSwords()
	{
		TArray<int> SwarmIndicesThatWillChangeShape;
		SwarmIndicesThatWillChangeShape.Reserve(4);

		for(int i = 0; i < Manager.Swarms.Num(); ++i)
		{
			ASwarmActor& SwarmIter = Manager.Swarms[i];

			// nullptr means vacant spot.
			if (SwarmIter == nullptr)
				continue;

			// ignore intro swarms until they are done
			UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(SwarmIter);
			if(ManagedSwarmComp.bIntroSwarm)
				continue;

			if(SwarmIter == Manager.MasterShield)
				continue;

			SwarmIndicesThatWillChangeShape.Add(i);
		}

		if(SwarmIndicesThatWillChangeShape.Num() > 0)
		{
			NetOrderRailSwordAttack(SwarmIndicesThatWillChangeShape);
		}

	}

	bool AreIntroSwarmsActive() const
	{
		for(ASwarmActor SwarmIter : Manager.Swarms)
		{
			// nullptr means vacant spot.
			if (SwarmIter == nullptr)
				continue;

			// ignore intro swarms until they are done
			UPhase3RailSwordComponent ManagedSwarmComp = UPhase3RailSwordComponent::GetOrCreate(SwarmIter);
			if(ManagedSwarmComp.bIntroSwarm)
				return true;

		}
		return false;
	}

	UFUNCTION(NetFunction)
	void NetOrderShieldFormation(TArray<int> Indicies)
	{
		for(int Index : Indicies)
		{
			if(Manager.Swarms[Index] == nullptr)
			{
				devEnsure(false, "Shield Formation has desynced. Not the same amount of the swarms on both sides.  \n Please let Sydney know about this");
				continue;
			}

			SwitchToShield(Manager.Swarms[Index]);
			Manager.Swarms[Index].OverrideBehaviourState(ESwarmBehaviourState::TelegraphDefence);
		}
		Manager.TimeStampShapeDuration = Time::GetGameTimeSeconds();
		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightThirdPhaseShieldWaspQueen", Queen);
	}

	UFUNCTION(NetFunction)
	void NetOrderRailSwordAttack(TArray<int> Indicies)
	{
		for(int Index : Indicies)
		{
			if(Manager.Swarms[Index] == nullptr)
			{
				devEnsure(false, "Number of rail swords attacking have desynced. \n Please let Sydney know about this");
				continue;
			}

			SwitchToRailSword(Manager.Swarms[Index]);
			Manager.Swarms[Index].OverrideBehaviourState(ESwarmBehaviourState::TelegraphInitial);
		}
		Manager.TimeStampShapeDuration = Time::GetGameTimeSeconds();
	}

	bool SwarmsAreRailSwording() const 
	{
		for (const auto IterSwarm : Manager.Swarms)
		{
			if(IterSwarm == nullptr)
				continue;

			if(IterSwarm == Manager.MasterShield)
				continue;

			if(!IsRailSword(IterSwarm))
				continue;
			
			// atleast 1
			return true;
		}
		return false;
	}

	bool SwarmsAreShielding() const 
	{
		for (const auto IterSwarm : Manager.Swarms)
		{
			if(IterSwarm == nullptr)
				continue;

			if(IterSwarm == Manager.MasterShield)
				continue;

			if(!IsShield(IterSwarm))
				continue;
			
			// atleast 1
			return true;
		}
		return false;
	}

	int GetNumPerformingRailSwordAttack() const
	{
		int NumPerforming = 0;
		for (const auto IterSwarm : Manager.Swarms)
		{
			if(IterSwarm == nullptr)
				continue;

			if(IsRailSword(IterSwarm))
				NumPerforming++;
		}
		return NumPerforming;
	}

	void DebugDrawSwarmLocations()
	{
		for(int i = 0; i < Manager.Swarms.Num(); ++i)
		{
			ASwarmActor& SwarmIter = Manager.Swarms[i];

			// nullptr means vacant spot.
			if (SwarmIter == nullptr)
				continue;

			FLinearColor Color = FLinearColor::Red;
			if(i == 0)
				Color = FLinearColor::Green;
			else if(i == 1)
				Color = FLinearColor::Yellow;
			else if(i == 2)
				Color = FLinearColor::LucBlue;
			else if(i == 3)
				Color = FLinearColor::Purple;


			System::DrawDebugSphere(
			SwarmIter.GetActorTransform().GetLocation(),
			100.f + i * 50.f, 8.f,
			Color,
			0.f
			);

		}
	}

	void DebugLists()
	{
		PrintToScreen("--------------------------");
		for(int i = 0; i < Manager.Swarms.Num(); ++i)
		{
			ASwarmActor& SwarmIter = Manager.Swarms[i];

			// nullptr means vacant spot.
			if (SwarmIter != nullptr)
				PrintToScreen("[" + i + "] " + SwarmIter.GetName());
			else
				PrintToScreen("[" + i + "] " + "nullptr");
		}

		PrintToScreen("SWARMS");
		PrintToScreen("--------------------------");

		PrintToScreen("\n");

		PrintToScreen("--------------------------");
		for(int i = 0; i < Manager.SlaveSwarms.Num(); ++i)
		{
			ASwarmActor& SwarmIter = Manager.SlaveSwarms[i];

			// nullptr means vacant spot.
			if (SwarmIter != nullptr)
				PrintToScreen("[" + i + "] " + SwarmIter.GetName());
			else
				PrintToScreen("[" + i + "] " + "nullptr");
		}
		PrintToScreen("SLAVES");
		PrintToScreen("--------------------------");

		PrintToScreen("\n");

		PrintToScreen("--------------------------");
		if (Manager.MasterShield != nullptr)
		{
			PrintToScreen("MasterShield: " + Manager.MasterShield.GetName());
			PrintToScreen("MasterShield Victim: " + Manager.MasterShield.VictimComp.PlayerVictim.GetName(), 0.f, FLinearColor::Yellow);
		}
		else
		{
			PrintToScreen("MasterShield: " + "nullptr");
		}
		PrintToScreen("--------------------------");
	}

}