import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessAudio.CastleChessBossAudioManager;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

class UCastleChessBossSpawnWaveAudioCapability : UHazeCapability
{
	ACastleChessBossAudioManager ChessAudioManager;
	UHazeAkComponent SpawnHazeAkComp;
	UHazeAkComponent AttackHazeAkComp;

	UPROPERTY(Category = "Spawning")
	UAkAudioEvent OnSpawnedPawns;
	
	UPROPERTY(Category = "Spawning")
	UAkAudioEvent OnSpawnedKnights;	

	UPROPERTY(Category = "Spawning")
	UAkAudioEvent OnSpawnedBishops;

	UPROPERTY(Category = "Spawning")
	UAkAudioEvent OnSpawnedRooks;

	UPROPERTY(Category = "Wave Attack")
	UAkAudioEvent PawnAttackEvent;

	UPROPERTY(Category = "Wave Attack")
	UAkAudioEvent BishopAttackEvent;

	UPROPERTY(Category = "Wave Attack")
	UAkAudioEvent KnightAttackEvent;

	UPROPERTY(Category = "Wave Attack")
	UAkAudioEvent RookAttackEvent;
	
	UPROPERTY(Category = "Despawning")
	UAkAudioEvent OnDespawnedPawnsEvent;
	
	UPROPERTY(Category = "Despawning")
	UAkAudioEvent OnDespawnedKnightsEvent;	

	UPROPERTY(Category = "Despawning")
	UAkAudioEvent OnDespawnedBishopsEvent;

	UPROPERTY(Category = "Despawning")
	UAkAudioEvent OnDespawnedRooksEvent;

	FChessPieceWaveGroup CurrentSpawnGroup;
	FChessPieceWaveGroup CurrentAttackGroup;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ChessAudioManager = Cast<ACastleChessBossAudioManager>(Owner);
		SpawnHazeAkComp = UHazeAkComponent::Create(ChessAudioManager, n"ChessWaveSpawnHazeAkComp");
		AttackHazeAkComp = UHazeAkComponent::Create(ChessAudioManager, n"ChessWaveAttackHazeAkComp");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		return EHazeNetworkActivation::ActivateLocal;
	}
	
	void OnWaveSpawned(FChessPieceWaveGroup& SpawnGroup)
	{
		ChessAudioManager.WaveGroups.Add(SpawnGroup);
		UAkAudioEvent WantedSpawnEvent;
		if(GetWaveGroup(EChessPieceGroupAudioState::Spawning, SpawnGroup))
		{
			if(!SpawnGroup.bHasPerformedSpawn)
			{
				switch(SpawnGroup.SpawnType)
				{
					case(ECastleChessSpawnType::Pawn):
						WantedSpawnEvent = OnSpawnedPawns;
						break;
					case(ECastleChessSpawnType::Knight):
						WantedSpawnEvent = OnSpawnedKnights;
						break;
					case(ECastleChessSpawnType::Rook):
						WantedSpawnEvent = OnSpawnedRooks;
						break;
					case(ECastleChessSpawnType::Bishop):
						WantedSpawnEvent = OnSpawnedBishops;
						break;
				}

				SpawnHazeAkComp.HazePostEvent(WantedSpawnEvent);

				for(auto ChessPiece : SpawnGroup.WavePieces)
				{
					UChessPieceComponent ChessPieceComp = UChessPieceComponent::Get(ChessPiece);
					ChessPiece.OnKilled.AddUFunction(this, n"OnChessPieceKilled");	
					ChessPieceComp.OnChessPieceAttack.AddUFunction(this, n"OnWavePerformedAttack");	
					ChessPieceComp.OnChessPieceDespawn.AddUFunction(this, n"OnWaveDespawned");
				}

				SpawnGroup.bHasPerformedSpawn = true;
				CurrentSpawnGroup = SpawnGroup;
				AdvanceWaveGroupState(EChessPieceGroupAudioState::Spawning, EChessPieceGroupAudioState::Attacking);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ChessAudioManager.bWaveSpawned = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ChessAudioManager.TempWaveGroups.Num() > 0)
		{
			for(int i = ChessAudioManager.TempWaveGroups.Num() - 1; i  >= 0; i--)
			{
				OnWaveSpawned(ChessAudioManager.TempWaveGroups[i]);
				ChessAudioManager.TempWaveGroups.RemoveAtSwap(i);
			}
		}

		if(CurrentSpawnGroup.WavePieces.Num() > 0)
		{
			const float SpawnPanningValue = GetWantedGroupCompPanning(CurrentSpawnGroup.WavePieces);
			HazeAudio::SetPlayerPanning(SpawnHazeAkComp, nullptr, SpawnPanningValue);

		}

		if(CurrentAttackGroup.WavePieces.Num() > 0)
		{
			const float AveragePanningValue = GetWantedGroupCompPanning(CurrentAttackGroup.WavePieces);
			HazeAudio::SetPlayerPanning(AttackHazeAkComp, nullptr, AveragePanningValue);	
		}
	}

	float GetWantedGroupCompPanning(const TArray<ACastleEnemy>& WaveGroup)
	{
		float Sum = 0.f;		
		for(auto& ChessPiece : WaveGroup)
		{
			if(ChessPiece != nullptr)
			{
				FVector2D ScreenPos;
				SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), ChessPiece.GetActorLocation(), ScreenPos);
				Sum += ScreenPos.X;
			}
		}

		return HazeAudio::NormalizeRTPC(Sum / WaveGroup.Num(), 0.f, 1.f, -1.f, 1.f);
	}

	UFUNCTION()
	void OnChessPieceKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		CurrentSpawnGroup.WavePieces.Remove(Enemy);
		CurrentAttackGroup.WavePieces.Remove(Enemy);
	}


	UFUNCTION()
	void OnWavePerformedAttack()
	{
		FChessPieceWaveGroup AttackGroup;
		if(GetWaveGroup(EChessPieceGroupAudioState::Attacking, AttackGroup))
		{
			if(AttackGroup.bHasPerformedAttack)
				return;

			UAkAudioEvent WantedAttackEvent;

			switch(AttackGroup.SpawnType)
			{
				case(ECastleChessSpawnType::Pawn):
					WantedAttackEvent = PawnAttackEvent;
					break;
				case(ECastleChessSpawnType::Knight):
					WantedAttackEvent = KnightAttackEvent;
					break;
				case(ECastleChessSpawnType::Rook):
					WantedAttackEvent = RookAttackEvent;
					break;
				case(ECastleChessSpawnType::Bishop):
					WantedAttackEvent = BishopAttackEvent;
					break;
			}

			AttackHazeAkComp.HazePostEvent(WantedAttackEvent);
			AttackGroup.bHasPerformedAttack = true;
			CurrentAttackGroup = AttackGroup;
			AdvanceWaveGroupState(EChessPieceGroupAudioState::Attacking, EChessPieceGroupAudioState::Despawning);			
		}
	}

	UFUNCTION()
	void OnWaveDespawned()
	{
		FChessPieceWaveGroup DespawnGroup;
		if(GetWaveGroup(EChessPieceGroupAudioState::Despawning, DespawnGroup))
		{
			UAkAudioEvent WantedDespawnEvent;

			switch(DespawnGroup.SpawnType)
			{
				case(ECastleChessSpawnType::Pawn):
					WantedDespawnEvent = OnDespawnedPawnsEvent;
					break;
				case(ECastleChessSpawnType::Knight):
					WantedDespawnEvent = OnDespawnedKnightsEvent;
					break;
				case(ECastleChessSpawnType::Rook):
					WantedDespawnEvent = OnDespawnedRooksEvent;
					break;
				case(ECastleChessSpawnType::Bishop):
					WantedDespawnEvent = OnDespawnedBishopsEvent;
					break;
			}

			AttackHazeAkComp.HazePostEvent(WantedDespawnEvent);
			ClearWaveGroup(DespawnGroup);			
		}
	}

	bool GetWaveGroup(const EChessPieceGroupAudioState State, FChessPieceWaveGroup& OutWaveGroup)
	{
		for(auto& WaveGroup : ChessAudioManager.WaveGroups)
		{
			if(WaveGroup.WaveState != State)
				continue;

			OutWaveGroup = WaveGroup;
			return true;
		}

		return false;
	}

	void ClearWaveGroup(FChessPieceWaveGroup& WaveGroup)
	{
		for(auto& ChessPiece : WaveGroup.WavePieces)
		{
			UChessPieceComponent ChessPieceComp = UChessPieceComponent::Get(ChessPiece);
			ChessPiece.OnKilled.Unbind(ChessAudioManager, n"OnChessPieceKilled");
			ChessPieceComp.OnChessPieceAttack.Clear();
			ChessPieceComp.OnChessPieceDespawn.Clear();	
		}

		ChessAudioManager.WaveGroups.Remove(WaveGroup);
	}

	void AdvanceWaveGroupState(EChessPieceGroupAudioState From, EChessPieceGroupAudioState To)
	{
		for(auto& WaveGroup : ChessAudioManager.WaveGroups)
		{
			if(WaveGroup.WaveState == From)
				WaveGroup.WaveState = To;
		}
	}

}