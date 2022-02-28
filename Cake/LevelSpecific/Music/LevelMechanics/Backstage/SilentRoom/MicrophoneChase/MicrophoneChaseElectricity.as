import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonsterCamera;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseManager;
import Vino.Movement.Components.MovementComponent;

class UMicrophoneChaseElectricityContainerComponent : UActorComponent
{
	AMicrophoneChaseElectricity Electricity;
}

UFUNCTION()
void SetMicrophoneChaseElectricity(AHazePlayerCharacter InPlayer, AMicrophoneChaseElectricity InElectricity)
{
	UMicrophoneChaseElectricityContainerComponent::GetOrCreate(InPlayer).Electricity = InElectricity;
}

event void FKillPlayerWithElectricity(FVector SeqActorLoc, FRotator SeqActorRot);



class AMicrophoneChaseElectricity : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraFX01;

	UPROPERTY()
	ASplineActor ConnectedSplineActor;

	UPROPERTY()
	AMicrophoneMonsterCamera Cam;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollow;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncedLocation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncedRotation;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartElectricityEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopElectricityEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KillElectricityEvent;

	UPROPERTY()
	UCurveFloat RubberbandingCurve;

	UPROPERTY()
	float MoveSpeed = 1400.f;

	UPROPERTY()
	FKillPlayerWithElectricity KillPlayerWithElectricityEvent;

	UPROPERTY()
	UNiagaraSystem ExplosionFX;

	UPROPERTY()
	AMicrophoneChaseManager MicrophoneChaseManager;

	FVector PlayerLocLastTick = FVector::ZeroVector;

	FVector CodyLastLoc;
	FVector MayLastLoc;
	float CodyLastDist;
	float MayLastDist;

	float PlayersStandingStillTimerDuration = .5f;
	float PlayersStandingStillTimer = 0.f;

	float Distance = 0.f;

	float MovedDistance = 0.0f;

	bool bShouldMove = false;
	float KillPlayerTimer = 0.f;

	float CurrentElectricityOffset = 2000.f;
	float ElectricityOffsetMax = 2000.f;

	private AHazePlayerCharacter Cody;
	private AHazePlayerCharacter May;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);

		Cody = Game::GetCody();
		May = Game::GetMay();
	}

	UFUNCTION()
	void StartMovingElectricity()
	{
		bShouldMove = true;
		SetActorHiddenInGame(false);
		SplineFollow.ActivateSplineMovement(ConnectedSplineActor.Spline);
		SetElectricityEnabled(true);
	}

	FVector GetControlPlayerPositionOnSpline() const
	{
		AHazePlayerCharacter Player = Game::GetMay().HasControl() ? Game::GetMay() : Game::GetCody();

		if(Player.IsPlayerDead())
		{
			Player = Player.IsMay() ? Game::GetCody() : Game::GetMay();
		}

		const FVector LocationOnSpline = ConnectedSplineActor.Spline.FindLocationClosestToWorldLocation(Player.ActorLocation, ESplineCoordinateSpace::World);
		return LocationOnSpline;
	}

	UFUNCTION()
	void SetElectricityEnabled(bool bEnabled)
	{
		SetActorHiddenInGame(!bEnabled); 
		//bShouldMove = bEnabled;
		//PrintToScreen("bEnabled: " + bEnabled, 3.f, FLinearColor::Red);

		if(!bEnabled)
			HazeAkComp.HazePostEvent(StopElectricityEvent);
		
		if (bEnabled)
			HazeAkComp.HazePostEvent(StartElectricityEvent);
	}

	// Stop moving and hide
	UFUNCTION()
	void ShutdownElectricity()
	{
		SetActorHiddenInGame(true);
		bShouldMove = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldMove)
			return;

		
		if (ShouldSlowdown())
		{
			CurrentElectricityOffset -= DeltaTime * 1500.f;
		} 
		else
		{
			PlayersStandingStillTimer = 0.f;
			CurrentElectricityOffset += DeltaTime * 1500.f;
			CurrentElectricityOffset = FMath::Min(CurrentElectricityOffset, ElectricityOffsetMax);
		}
			
		float MiddleDist = GetElectricityDistance();
		MiddleDist -= CurrentElectricityOffset;
		//PrintToScreen("CurrentElectricityOffset " + CurrentElectricityOffset);

		const FVector NewLocation = ConnectedSplineActor.Spline.GetLocationAtDistanceAlongSpline(MiddleDist, ESplineCoordinateSpace::World);
		const FRotator NewRotation = ConnectedSplineActor.Spline.GetRotationAtDistanceAlongSpline(MiddleDist, ESplineCoordinateSpace::World);

		SetActorLocation(NewLocation);
		SetActorRotation(NewRotation);

		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Events_MicrophoneChase_Electricity_Distance", CurrentElectricityOffset);
		

		CodyLastDist = CodyDistanceOnSpline;
		MayLastDist = MayDistanceOnSpline;
	}

	float GetElectricityDistance() const
	{
		/*if(Network::IsNetworked())
		{
			if(!PlayerInControl.IsPlayerDead())
				return ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(PlayerInControl.ActorLocation);
			else
			{
				FHazeActorReplicationFinalized CrumbParams;
				UHazeCrumbComponent::Get(RemotePlayer).GetCurrentReplicatedData(CrumbParams);
				return ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(CrumbParams.Location);
			}
		}*/

		if(AreBothPlayersAlive())
		{
			FVector MiddlePosBetweenPlayers = FVector(CodyLocation + MayLocation) * 0.5f;
			float MiddleDist = ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(MiddlePosBetweenPlayers);
			return MiddleDist;
		}

		if(!Cody.IsPlayerDead())
			return CodyDistanceOnSpline;

		return MayDistanceOnSpline;
	}

	UFUNCTION(NetFunction)
	private void NetKillPlayers(FVector Loc, FRotator Rot)
	{
		KillPlayerWithElectricityEvent.Broadcast(Loc, Rot);
		SetElectricityEnabled(false);
	}

	bool AreBothPlayersAlive() const
	{
		const bool bIsCodyAlive = Cody.IsPlayerDead();
		const bool bIsMayAlive = May.IsPlayerDead();
		return bIsCodyAlive && bIsMayAlive;
	}

	bool ShouldSlowdown() const
	{
		if(Network::IsNetworked())
		{
			if(!PlayerInControl.IsPlayerDead())
			{
				const float ControlPlayerLastDistance = PlayerInControl.IsMay() ? MayLastDist : CodyLastDist;
				const bool bIsControlPlayerMoving = IsPlayerMoving(PlayerInControl, ControlPlayerLastDistance);
				return !bIsControlPlayerMoving;
			}
			else
			{
				const float RemotePlayerLastDistance = RemotePlayer.IsMay() ? MayLastDist : CodyLastDist;
				const bool bIsRemotePlayerMoving = IsPlayerMoving(RemotePlayer, RemotePlayerLastDistance);
				return !bIsRemotePlayerMoving;
			}
		}

		bool bIsCodyMoving = IsPlayerMoving(Cody, CodyLastDist);
		bool bIsMayMoving = IsPlayerMoving(May, MayLastDist);

		return !bIsMayMoving && !bIsCodyMoving;
	}

	bool IsPlayerMoving(AHazePlayerCharacter InPlayer, float LastDistance) const
	{
		const bool bIsPlayerDead = InPlayer.IsPlayerDead();

		if(bIsPlayerDead)
			return false;

		const float DistOnSpline = GetPlayerDistanceOnSpline(InPlayer);
		bool bIsMoving = DistOnSpline > LastDistance;
		return bIsMoving;
	}

	FVector GetCodyLocation() const property
	{
		if(!devEnsure(Cody != nullptr))
			return FVector::ZeroVector;
		return Cody.ActorLocation;
	}

	FVector GetMayLocation() const property
	{
		if(!devEnsure(May != nullptr))
			return FVector::ZeroVector;
		return May.ActorLocation;
	}

	float GetMayDistanceOnSpline() const property
	{
		return ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(MayLocation);
	}

	float GetCodyDistanceOnSpline() const property
	{
		return ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(CodyLocation);
	}

	float GetPlayerDistanceOnSpline(AHazePlayerCharacter InPlayer) const
	{
		return ConnectedSplineActor.Spline.GetDistanceAlongSplineAtWorldLocation(InPlayer.ActorLocation);
	}

	AHazePlayerCharacter GetPlayerInControl() const property
	{
		return May.HasControl() ? May : Cody;
	}

	AHazePlayerCharacter GetRemotePlayer() const property
	{
		return !May.HasControl() ? May : Cody;
	}
}
