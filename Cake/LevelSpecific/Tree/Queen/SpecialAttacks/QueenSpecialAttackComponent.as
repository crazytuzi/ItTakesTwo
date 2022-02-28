import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.LevelSpecific.Tree.Swarm.SwarmStatics;
import Cake.Weapons.Sap.SapWeaponNames;
import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class UQueenSpecialAttackComponent : UActorComponent
{
	UPROPERTY()
	bool bIsRunningAttack = false;

	UPROPERTY()
	AHazeLevelSequenceActor ElevateQueenLevelSequence;

	UPROPERTY()
	AHazeLevelSequenceActor LowerQueenLevelSequence;

	bool bBlockedMayWeapon;
	bool bBlockedCodyWeapon;

	UPROPERTY()
	int Order = 0;

	UFUNCTION(BlueprintPure)
	bool CanUse()
	{
		return true;
	}

	UPROPERTY()
	AQueenActor Queen;

	UPROPERTY()
	AHazePlayerCharacter PlayerInFullScreen;

	UFUNCTION()
	void StartLetterbox()
	{
		for (auto player : Game::GetPlayers())
		{
			player.SetShowLetterbox(true);
		}
	}

	UFUNCTION()
	void RespawnPlayers()
	{
		TArray<AHazePlayerCharacter> DeadPlayers;

		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsPlayerDead() && Player.HasControl())
			{
				DeadPlayers.Add(Player);
			}
		}

		for (auto i : DeadPlayers)
		{
			NetTeleportPlayerForRespawn(i);
		}
	}

	UFUNCTION(NetFunction)
	void NetTeleportPlayerForRespawn(AHazePlayerCharacter Player)
	{
		ForcePlayersToBeAlive();
		Player.TeleportActor(Queen.RespawnLocation.ActorTransform.Location, Queen.RespawnLocation.ActorTransform.Rotation.Rotator());
	}

	UFUNCTION()
	void SetFullHealth()
	{
		for (auto player : Game::GetPlayers())
		{
			player.HealPlayerHealth(1);
		}
	}

	UFUNCTION()
	void StopLetterbox()
	{
		for (auto player : Game::GetPlayers())
		{
			player.SetShowLetterbox(false);
			
		}
	}

	UFUNCTION()
	void RemovePhysicsOnQueen()
	{
		Queen.Mesh.SetSimulatePhysics(false);
		UPhysicsConstraintComponent::Get(Queen).BreakConstraint();
	}

	UFUNCTION()
	void BlockWeapons()
	{
		for (auto player : Game::GetPlayers())
		{
			if (player.IsCody())
			{
				bBlockedCodyWeapon = true;
			}

			else
			{
				bBlockedMayWeapon = true;
			}
			
			player.BlockCapabilities(ActionNames::WeaponAim, this);
			player.BlockCapabilities(ActionNames::WeaponFire, this);
		}
	}

	UFUNCTION()
	void BlockGrindSplines(bool _ShouldBlock)
	{
		Queen.GrindSpline.bCanJump = !_ShouldBlock;
		Queen.GrindSpline.bCanLandOn = !_ShouldBlock;
		Queen.GrindSpline.bCanGrappleTo = !_ShouldBlock;
	}

	UFUNCTION()
	void UnblockWeapons()
	{
		for (auto player : Game::GetPlayers())
		{
			if (player.IsCody() && bBlockedCodyWeapon || !player.IsCody() && bBlockedMayWeapon)
			{
				if (player.IsCody())
				{
					bBlockedCodyWeapon = false;
				}
				else
				{
					bBlockedMayWeapon = false;
				}
				player.UnblockCapabilities(ActionNames::WeaponAim, this);
				player.UnblockCapabilities(ActionNames::WeaponFire, this);
			}
		}
	}

	UFUNCTION()
	void RestorePlayerHealth()
	{
		for (auto player : Game::Players)
		{
			player.HealPlayerHealth(1.f);
		}
	}

	UFUNCTION()
	void UnBlockWeaponsForPlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsCody() && bBlockedCodyWeapon)
		{
			bBlockedCodyWeapon = false;	
			Player.UnblockCapabilities(SapWeaponTags::Aim, this);
			Player.UnblockCapabilities(n"Weapon", this);
		}

		else if (!Player.IsCody() && bBlockedMayWeapon)
		{
			bBlockedMayWeapon = false;	
			Player.UnblockCapabilities(SapWeaponTags::Aim, this);
			Player.UnblockCapabilities(n"Weapon", this);
		}
		else 
			return;

		
	}

	UFUNCTION()
	void ReEnablePhysicsOnQueen()
	{
		Queen.Mesh.SetSimulatePhysics(true);
		UPhysicsConstraintComponent::Get(Queen).SetConstrainedComponents(Queen.Mesh, NAME_None, nullptr, NAME_None);
	}

	UFUNCTION(NetFunction)
	void NetActivateSpecialAttack()
	{
		Queen.SetCapabilityActionState(n"SpecialAttack", EHazeActionState::Active);	
		SpecialAttackActivated();
	}

	UFUNCTION()
	void EnableRailBlockerSwarms()
	{
		if (Queen.RailBlockerSwarmLeft.IsActorDisabled())
		{
			Queen.RailBlockerSwarmLeft.EnableActor(Queen);
			Queen.RailBlockerSwarmRight.EnableActor(Queen);
		}
	}

	UFUNCTION()
	void DisableRailBlockerSwarms()
	{
		if (Queen.RailBlockerSwarmLeft.IsActorDisabled())
		{
			Queen.RailBlockerSwarmLeft.DisableActor(Queen);
			Queen.RailBlockerSwarmRight.DisableActor(Queen);
		}
	}

	UFUNCTION(BlueprintEvent)
	void SpecialAttackActivated()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void ActivatePullUpSequence()
	{
		Queen.OnSpecialAttackStarted.Broadcast(this);
		Queen.AnimData.bAscending = true;
	}

	UFUNCTION()
	void PullDownSequenceDone()
	{
		Queen.SetCapabilityActionState(n"SpecialAttack", EHazeActionState::Inactive);
		Queen.OnSpecialAttackDone.Broadcast(this);
	}

	UFUNCTION(BlueprintEvent)
	void ActivatePullDownSequence()
	{
		Queen.AnimData.bAscending = false;
	}
	
	UFUNCTION()
	void SetGrindingEnabled(bool Enabled)
	{
		for (auto player : Game::GetPlayers())
		{
			if (Enabled)
			{
				player.UnblockCapabilities(MovementSystemTags::Grinding, this);
			}
			else
			{
				player.BlockCapabilities(MovementSystemTags::Grinding, this);
			}
		}
	}

	UFUNCTION()
	void TriggerFullScreen()
	{
		PlayerInFullScreen = GetFullScreenPlayer();
		PlayerInFullScreen.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
	}

	UFUNCTION()
	AHazePlayerCharacter GetFullScreenPlayer()
	{
		if (Queen.BehindQueenArea.IsOverlappingActor(Game::Cody))
		{
			return Game::GetMay();
		}

		else if (Queen.BehindQueenArea.IsOverlappingActor(Game::May))
		{
			return Game::GetCody();
		}

		else
		{
			return Game::GetCody();
		}
	}

	UFUNCTION()
	void ResetFullScreen()
	{
		Game::GetCody().ClearViewSizeOverride(this);
		Game::GetMay().ClearViewSizeOverride(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsRunningAttack()
	{
		return bIsRunningAttack;
	}
}