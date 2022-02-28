import Peanuts.Spline.SplineActor;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonsterCamera;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseRespawnSpline;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseCheckpoint;
import Peanuts.AutoMove.CharacterAutoMoveComponent;

event void FMicrophoneChaseManagerDelegate();

// For easy reference on the player
class UMicrophoneChaseManagerComponent : UActorComponent
{
	AMicrophoneChaseManager MicrophoneChaseMgr = nullptr;
}

class AMicrophoneChaseManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	ASplineActor SplineActor;	

	UPROPERTY()
	AMicrophoneMonster MicrophoneMonster;

	UPROPERTY()
	USprintSettings SprintSettings;

	UPROPERTY()
	UCurveFloat RubberbandingCurve;

	UPROPERTY()
	UCurveFloat RubberbandingCurve_Remote;

	UPROPERTY()
	bool bDebugMode = false;

	UPROPERTY()
	AActor GrindJumpToActor;

	UPROPERTY()
	AMicrophoneChaseCheckpoint ChaseCheckpoint;

	AMicrophoneChaseRespawnSpline CurrentRespawnSpline;

	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	float BaseSpeed = 0.f;
	float SpeedMultiplier = 1.f;

	int NumDoorsInteracted = 0;
	int NumDoorsClosed = 0;

	bool bControlSaysOkayToDie = false;
	bool bControlSaysWeAreSafe = false;
	bool bStartedApproachingDoors = false;
	bool bDoorsClosedInTime = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseSpeed = SprintSettings.MoveSpeed;

		UMicrophoneChaseManagerComponent MayChaseMgr = UMicrophoneChaseManagerComponent::GetOrCreate(Game::GetMay());
		MayChaseMgr.MicrophoneChaseMgr = this;
		Reset::RegisterPersistentComponent(MayChaseMgr);
		
		UMicrophoneChaseManagerComponent CodyChaseMgr =  UMicrophoneChaseManagerComponent::GetOrCreate(Game::GetCody());
		CodyChaseMgr.MicrophoneChaseMgr = this;
		Reset::RegisterPersistentComponent(CodyChaseMgr);

		ChaseCheckpoint.OnRespawnAtCheckpoint.AddUFunction(this, n"Respawned");
		MicrophoneMonster.OnEnteredExitLane.AddUFunction(this, n"Handle_EnteredExitLane");
	}

	UFUNCTION()
	private void Handle_EnteredExitLane()
	{
		if(!HasControl())
			return;

		if(bDoorsClosedInTime)
		{
			NetSafeFromMicrophoneMonster();
		}
		else
		{
			NetReadyToDie();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UMicrophoneChaseManagerComponent MayChaseMgr = UMicrophoneChaseManagerComponent::Get(Game::GetMay());
		if(MayChaseMgr != nullptr)
		{
			MayChaseMgr.MicrophoneChaseMgr = nullptr;
			Reset::UnregisterPersistentComponent(MayChaseMgr);
		}

		UMicrophoneChaseManagerComponent CodyChaseMgr = UMicrophoneChaseManagerComponent::Get(Game::GetCody());
		if(CodyChaseMgr != nullptr)
		{
			CodyChaseMgr.MicrophoneChaseMgr = nullptr;
			Reset::UnregisterPersistentComponent(CodyChaseMgr);
		}
	}

	float GetRubberbandSpeedMultiplier(AHazePlayerCharacter InPlayer)
	{
		if (bDebugMode)
			return 0.f;

		if (IsPlayerFirst(InPlayer))
			return 0.f;
		
		if (InPlayer.IsPlayerDead() || InPlayer.GetOtherPlayer().IsPlayerDead())
			return 0.f;

		float DistanceBetweenPlayers = (InPlayer.ActorLocation - GetOtherPlayerLocation(InPlayer)).Size();
		SpeedMultiplier = RubberbandingCurve.GetFloatValue(FMath::GetMappedRangeValueClamped(FVector2D(0.f, 2500.f), FVector2D(0.f, 1.f), DistanceBetweenPlayers));

		return SpeedMultiplier;
	}

	FVector GetOtherPlayerLocation(AHazePlayerCharacter InPlayer) const
	{
		const bool bIsNetworked = Network::IsNetworked();
		AHazePlayerCharacter OtherPlayer = InPlayer.OtherPlayer;
		const FVector OtherPlayerLocation = bIsNetworked ? GetPredictionLocation(OtherPlayer) : OtherPlayer.ActorLocation;
		return OtherPlayerLocation;
	}

	AHazePlayerCharacter GetPlayerInFirstPlace()
	{
		AHazePlayerCharacter FirstPlayer;
		
		TArray<AHazePlayerCharacter> PlayerArray;
		PlayerArray.Add(Game::GetCody());
		PlayerArray.Add(Game::GetMay());

		float LeadingDistance = 0.f;
		
		for (int i = 0; i < PlayerArray.Num(); i++)
		{
			FHazeSplineSystemPosition Pos = SplineActor.Spline.GetPositionClosestToWorldLocation(PlayerArray[i].GetActorLocation(), true);
			float Dist = SplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(Pos.WorldLocation);
			if (Dist > LeadingDistance)
			{
				LeadingDistance = Dist;
				FirstPlayer = PlayerArray[i];
			}
		}
		
		return FirstPlayer;
	}

	bool IsPlayerFirst(AHazePlayerCharacter InPlayer) const
	{
		FVector OtherPlayerLocation = GetOtherPlayerLocation(InPlayer);

		FHazeSplineSystemPosition PlayerSplineLoc = SplineActor.Spline.GetPositionClosestToWorldLocation(InPlayer.ActorLocation, true);
		FHazeSplineSystemPosition OtherPlayerSplineLoc = SplineActor.Spline.GetPositionClosestToWorldLocation(OtherPlayerLocation, true);

		const float PlayerDist = SplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(PlayerSplineLoc.WorldLocation);
		const float OtherPlayerDist = SplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(OtherPlayerSplineLoc.WorldLocation);

		const bool bIsPlayerFirst = PlayerDist > OtherPlayerDist;
		return bIsPlayerFirst;
	}


	FVector GetPredictionLocation(AHazePlayerCharacter InPlayer) const
	{
		FHazeActorReplicationFinalized CrumbParams;
		UHazeCrumbComponent::Get(InPlayer).GetCurrentReplicatedData(CrumbParams);
		return CrumbParams.Location + CrumbParams.Velocity * Network::GetPingRoundtripSeconds() * 0.5f;
	}

	void OnDoorInteraction(AHazePlayerCharacter Player)
	{
		NumDoorsInteracted++;

		if(NumDoorsInteracted > 1)
		{
			if(Player.HasControl())
			{
				OnStartMicrophoneChaseApproachDoors.Broadcast();
				bStartedApproachingDoors = true;
			}
			else
			{
				// Delay the remote start a little bit.
				UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
				if(!devEnsure(CrumbComp != nullptr))
					System::SetTimer(this, n"StartDelayedApproachOnRemote", 0.2f, false);
				else
					System::SetTimer(this, n"StartDelayedApproachOnRemote", CrumbComp.PredictionLag, false);
			}
		}
	}

	// Called when the microphone should start appearing towards the players. Started when the second player grabs the door.
	UPROPERTY()
	FMicrophoneChaseManagerDelegate OnStartMicrophoneChaseApproachDoors;

	// Called when the microphone monster reaches the end of the spline and the doors are closed in time.
	UPROPERTY()
	FMicrophoneChaseManagerDelegate OnDoorsClosedInTime;

	// Called when the microphone monster reaches the end of the spline and the doors are not closed.
	UPROPERTY()
	FMicrophoneChaseManagerDelegate OnKilledByMicrophoneMonster;

	// Called when the players have failed to close the door in time.
	UPROPERTY()
	FMicrophoneChaseManagerDelegate OnOnPlayersReadyToDie;

	UFUNCTION()
	void StartDelayedApproachOnRemote()
	{
		OnStartMicrophoneChaseApproachDoors.Broadcast();
		bStartedApproachingDoors = true;
	}

	void OnClosedDoor()
	{
		NumDoorsClosed++;

		if(NumDoorsClosed > 1 && HasControl())
		{
			bDoorsClosedInTime = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateCheckpointLocation();

		if(bStartedApproachingDoors)
		{
			UpdateApproachDoors(DeltaTime);
		}
	}

	private void UpdateApproachDoors(float DeltaTime)
	{
		if(HasControl() && MicrophoneMonster.bEndOfCurrentSpline && bControlSaysWeAreSafe)
		{
			DetachPlayerFromDoor(Game::GetCody());
			DetachPlayerFromDoor(Game::GetMay());
		}

		if(MicrophoneMonster.bEndOfCurrentSpline && bControlSaysWeAreSafe)
		{
			OnDoorsClosedInTime.Broadcast();
			bStartedApproachingDoors = false;
		}
		else if(MicrophoneMonster.bEndOfCurrentSpline && bControlSaysOkayToDie)
		{
			OnKilledByMicrophoneMonster.Broadcast();
			bStartedApproachingDoors = false;
		}
	}

	void DetachPlayerFromDoor(AHazePlayerCharacter Player)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld);	
	}

	UFUNCTION(NetFunction)
	void NetReadyToDie()
	{
		bControlSaysOkayToDie = true;
		OnOnPlayersReadyToDie.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetSafeFromMicrophoneMonster()
	{
		bControlSaysWeAreSafe = true;
	}

	UFUNCTION()
	void SetChaseRespawnSpline(AMicrophoneChaseRespawnSpline Spline)
	{
		CurrentRespawnSpline = Spline;
	}

	void UpdateCheckpointLocation()
	{
		if (CurrentRespawnSpline == nullptr)
			return;

		float Dist = CurrentRespawnSpline.Spline.GetDistanceAlongSplineAtWorldLocation(GetPlayerInFirstPlace().GetActorLocation()); 
		FVector Loc = CurrentRespawnSpline.Spline.GetLocationAtDistanceAlongSpline(FMath::Min(Dist + 600.f, CurrentRespawnSpline.Spline.GetSplineLength()), ESplineCoordinateSpace::World);
		FRotator Rot = CurrentRespawnSpline.Spline.GetRotationAtDistanceAlongSpline(FMath::Min(Dist + 600.f, CurrentRespawnSpline.Spline.GetSplineLength()), ESplineCoordinateSpace::World);
		ChaseCheckpoint.UpdateChaseCheckpointLocationAndRotation(Loc, Rot);
	}

	UFUNCTION()
	void SetRespawnForPlayersEnabled(bool bEnabled)
	{
		/*if (bEnabled)
		{
			for (auto Player : Game::GetPlayers())
				Player.UnblockCapabilities(n"Respawn", this);

		} else 
		{
			for (auto Player : Game::GetPlayers())
				Player.BlockCapabilities(n"Respawn", this);
		}*/
	}

	UFUNCTION()
	void Respawned(AHazePlayerCharacter Player)
	{
		Player.AutoMoveCharacterAlongSpline(CurrentRespawnSpline.Spline);
	}
}
