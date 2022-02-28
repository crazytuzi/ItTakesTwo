import Vino.Movement.MovementSettings;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Waternado.WaternadoNode;
import Cake.LevelSpecific.Tree.Waternado.WaternadoMovementComponent;
import Cake.LevelSpecific.Tree.Waternado.WaternadoPlayerResponseComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;
import Vino.Camera.Components.WorldCameraShakeComponent;

/*
	VFX water tornado that replaces the wasp tornado/hurricane in the boat section of tree
 */

UCLASS(abstract, HideCategories = "Debug Actor Replication Input Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation Mobile MeshOffset Activation LOD")
class AWaternado : AHazeActor 
{
	UPROPERTY(Category = "Nado Debug")
	bool bDebugPlayerAttackInEditor = true;
	bool bPrevDebugPlayerAttackInEditor = false;

	UPROPERTY(Category = "Nado Debug")
	bool bDebugPlayerAttackInRuntime = false;

	// nado will attack player when he/she enter this radius
	UPROPERTY(Category = "Nado Attack")
	float EnableAttackRadius = 6000.f;

	/* nado will stop attacking if the player
	 if the distance between him and the nearest node is greated then this vlaue */
	UPROPERTY(Category = "Nado Attack")
	float DisableAttackRadius = 8000.f;

	// how long THIS nado has to wait until it can attack again
	UPROPERTY(Category = "Nado Attack")
	float AttackPlayerCooldown = 2.f;

	UPROPERTY(Category = "bAllowTick")
	bool bAllowTick = true;

	UPROPERTY(Category = "Juice")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	/* Will be pushed on the player when overlapping the nado
		The capability will have reference to assets and handle everything */
	UPROPERTY(Category = "Nado Attack")
	TSubclassOf<UHazeCapability> PlayerOverlapResponseCapability;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FoghornBank;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UWaternadoMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CollisionComp;

//	UPROPERTY(DefaultComponent)
//	UHazeSmoothSyncVectorComponent NetSyncWorldLocation;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SpawnSplash1;
	default SpawnSplash1.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SpawnSplash2;
	default SpawnSplash2.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompWaternado;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;
	default ForceFeedbackComp.bOverrideAttenuation = true;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent WorldCameraShakeComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpawnWaternadoAudioEvent;

	////////////////////////////////7
	// TRANSIENTS

	private TPerPlayer<float> DistanceToPlayerSQ;

	UHazeAITeam Team;
	float TimeStampEndPlayerAttack = -AttackPlayerCooldown;
	AHazePlayerCharacter PlayerVictim = nullptr;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR
		DrawDebugPlayerAtack();
#endif

	}

	float CameraShakeDistanceThresholdSQ = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

#if EDITOR
		System::FlushPersistentDebugLines();
#endif

		Team = JoinTeam(n"WaternadoTeam");
		if(PlayerOverlapResponseCapability.IsValid())
			Team.AddPlayersCapability(PlayerOverlapResponseCapability.Get());

		Team.AddPlayersCapability(PlayerOverlapResponseCapability.Get());

		//HazeAkCompWaternado.HazePostEvent(SpawnWaternadoAudioEvent);

		// AddCapability(n"WaterspoutFollowNodeCapability");
		// AddCapability(n"WaternadoHandleOverlapsCapbility");

		SetControlSide(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(const float Dt)
	{
		if(!bAllowTick)
			return;

		UpdateDistanceToPlayers();

		HandlePlayerOverlaps();

//		ForceFeedbackComp.DrawDebugForceFeedbackComponent();

		if(MoveComp.CurrentNode == nullptr)
			return;

		// make nado follow water height differences in Z
		MoveComp.UpateWaterSurfaceHeight(Dt);

		HandlePlayerVictimAssignment();

		// attack player once we find one
		if (PlayerVictim != nullptr)
		{
			if(IsOverlappingOtherNadoAttacks())
				NetEndPlayerAttack();
			else
				UpdateAttackOnPlayerMovement(Dt);
		}
		else
		{
			// walk around on spline until we find a player
			MoveComp.UpdateSplineMovement(Dt);
		}

//		// Sync Movement
//		if(HasControl())
//			NetSyncWorldLocation.Value = GetActorLocation();
//		else
//			SetActorLocation(NetSyncWorldLocation.Value);

		UpdateCameraShake();
		UpdateVO();

#if EDITOR
		MoveComp.DebugHideNodes();
		MoveComp.DebugDrawNodePath();
		MoveComp.DebugDrawCurrentLocation();
		DrawDebugPlayerAtack(true);
#endif

	}

	void UpdateDistanceToPlayers()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player == nullptr)
				continue;

			DistanceToPlayerSQ[Player] = (GetActorLocation() - Player.GetActorLocation()).SizeSquared();
		}
	}

	void UpdateCameraShake()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player == nullptr)
				continue;

			if (!Player.MovementComponent.IsGrounded())
			{
				WorldCameraShakeComp.StopForPlayer(Player);
				continue;
			}

			if (DistanceToPlayerSQ[Player] <= FMath::Square(WorldCameraShakeComp.OuterRadius))
			{
				if (!WorldCameraShakeComp.HasActiveInstance(Player))
				{
					WorldCameraShakeComp.PlayForPlayer(Player);
					continue;
				}

				WorldCameraShakeComp.RefreshShakeLocationForPlayer(Player);
			}
			else
			{
				WorldCameraShakeComp.StopForPlayer(Player);
			}
		}
	}

	void HandlePlayerVictimAssignment()
	{
		if(IsAttackOnCooldown())
		{
			PlayerVictim = nullptr;
			return;
		}

		if (!HasControl())
			return;

		// Cancel ongoing attack when nado moves outside of max range 
		// We are basically checking if the player is kiting the nado
		if(IsOutsideOfAttackRange())
		{
			if(PlayerVictim != nullptr)
				NetEndPlayerAttack();
			return;
		}

		const bool bHadPlayerVictim = PlayerVictim != nullptr;

		AHazePlayerCharacter NewVictim = FindClosestAttackablePlayer(EnableAttackRadius);
		if(NewVictim != PlayerVictim && GetTimeSinceVictimAssignment() > 0.1f)
		{
			NetAssignPlayerVictim(NewVictim);
		}

		// lost player victim
		if(bHadPlayerVictim && PlayerVictim == nullptr)
			NetEndPlayerAttack();
	}

	float TimeStampVictimAssignment = -1.f;

	UFUNCTION(NetFunction)
	void NetAssignPlayerVictim(AHazePlayerCharacter InPlayerVictim)
	{
		TimeStampVictimAssignment = Time::GetGameTimeSeconds();
		PlayerVictim = InPlayerVictim;

//		if(PlayerVictim != nullptr)
//			Print("Assign Player Victim: " + PlayerVictim.GetName());
	}

	float GetTimeSinceVictimAssignment() const
	{
		return Time::GetGameTimeSince(TimeStampVictimAssignment);
	}

	bool IsOutsideOfAttackRange() const
	{
		const float DistFromStartSQ = MoveComp.StartLocation.DistSquared(GetActorLocation());
		return DistFromStartSQ > FMath::Square(DisableAttackRadius);
	}

	bool IsPlayerGrounded(AHazePlayerCharacter InPlayer) const
	{
		return UHazeMovementComponent::Get(InPlayer).IsGrounded();
	}

	void HandlePlayerOverlaps()
	{
		TArray<AHazePlayerCharacter> IntersectingPlayers;
		if(FindIntersectingPlayer(IntersectingPlayers) == false)
			return;

		// Push overlap notification to players
		for(auto OverlappedPlayer : IntersectingPlayers)
		{
			if(!CanAttackPlayer(OverlappedPlayer))
				continue;

			OverlappedPlayer.SetCapabilityAttributeObject(n"OverlappedWaternado", this);
			OverlappedPlayer.SetCapabilityActionState(n"WaternadoImpulse", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		WorldCameraShakeComp.Stop();
		return false;
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		WorldCameraShakeComp.Stop();
        LeaveTeam(n"WaternadoTeam");
		Team = nullptr;
    }

	bool FindIntersectingPlayer(TArray<AHazePlayerCharacter>& OutOverlappedPlayers) const
	{
		AHazePlayerCharacter May = nullptr;
		AHazePlayerCharacter Cody = nullptr;
		Game::GetMayCody(May, Cody);

		if (ArePlayerBoundsIntersected(May) && IsOverlappingPlayer(May))
		{
			OutOverlappedPlayers.AddUnique(May);
		}
			

		if (ArePlayerBoundsIntersected(Cody) && IsOverlappingPlayer(Cody))
		{
			OutOverlappedPlayers.AddUnique(Cody);	
		}
			

		return OutOverlappedPlayers.Num() > 0;
	}

	bool ArePlayerBoundsIntersected(AHazePlayerCharacter InPlayer) const
	{
		return Math::AreComponentBoundsIntersecting( CollisionComp, InPlayer.CapsuleComponent); 
	}

	bool IsOverlappingPlayer(AHazePlayerCharacter InPlayer) const
	{
		return Trace::ComponentOverlapComponent(
			InPlayer.CapsuleComponent,
			CollisionComp,
			CollisionComp.GetWorldLocation(),
			CollisionComp.GetComponentQuat(),
			false	// Complex
		);
	}

	AHazePlayerCharacter FindClosestAttackablePlayer(const float SearchForPlayerRadius = 100000.f) const
	{
		const FVector WaternadoLocation = GetActorLocation();

		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		// UHazeMovementComponent MoveComp_May = UHazeMovementComponent::Get(May);
		// UHazeMovementComponent MoveComp_Cody = UHazeMovementComponent::Get(Cody);

		if(CanAttackPlayer(May) && CanAttackPlayer(Cody))
		// if(MoveComp_Cody.IsGrounded() && MoveComp_May.IsGrounded())
		{
			const float DistSQ_May = May.GetSquaredDistanceTo(this);
			const float DistSQ_Cody = Cody.GetSquaredDistanceTo(this);

			if(DistSQ_May < DistSQ_Cody)
			{
				if(DistSQ_May < FMath::Square(SearchForPlayerRadius))
				{
					return May;
				}
			}
			else if(DistSQ_Cody < FMath::Square(SearchForPlayerRadius))
			{
				return Cody;
			}
		}
		else if(CanAttackPlayer(Cody))
		// else if(MoveComp_Cody.IsGrounded())
		{
			const float DistSQ_Cody = Cody.GetSquaredDistanceTo(this);
			if(DistSQ_Cody < FMath::Square(SearchForPlayerRadius))
			{
				return Cody;
			}
		}
		// else if(MoveComp_May.IsGrounded())
		else if(CanAttackPlayer(May))
		{
			const float DistSQ_May = May.GetSquaredDistanceTo(this);
			if(DistSQ_May < FMath::Square(SearchForPlayerRadius))
			{
				return May;
			}
		}

		return nullptr;
	}

	// Specific for the first waternado only! (The one in the cutscene)
	UFUNCTION(BlueprintCallable)
	void InitializeWaternadoAfterTransition()
	{
		bAllowTick = true;

		// you forgot to assign the start node which it is supposed to follow.
		ensure(MoveComp.CurrentNode != nullptr);

		MoveComp.Initialize();
	}

	bool IsOverlappingOtherNadoAttacks() const
	{
		// assuming this func is only called when we are attacking
		ensure(PlayerVictim != nullptr);

		if(Team == nullptr)
		{
			// We join the team on begin play, why is it null!?
			ensure(false);
			return false;
		}

		for(AHazeActor TeamMember : Team.GetMembers())
		{
			if(TeamMember == nullptr)
				continue;

			if(TeamMember == this)
				continue;

			AWaternado Othernado = Cast<AWaternado>(TeamMember);

			if (Othernado == nullptr)
				continue;
			
			if(PlayerVictim != Othernado.PlayerVictim)
				continue;

			if(Math::AreComponentBoundsIntersecting(CollisionComp, Othernado.CollisionComp))
			{
				const float DistToPlayer = GetSquaredDistanceTo(PlayerVictim);
				const float OtherDistToPlayer = Othernado.GetSquaredDistanceTo(PlayerVictim);
				if(OtherDistToPlayer < DistToPlayer)
				{
					return true;
				}
			}

		}

		return false;
	}

	void UpdatePlayerAttack(const float Dt)
	{
	}
	
	void UpdateAttackOnPlayerMovement(const float Dt)
	{
		// linear movement towards it if we are close enough
		FVector PlayerPos = PlayerVictim.GetActorLocation();
		const FVector WaternadoPos = GetActorLocation();

		FVector ToPlayer = PlayerPos - WaternadoPos;

		if (MoveComp.WaterSurfaceActor != nullptr)
		{
			// Make the attack horizontal when following the water surface
			ToPlayer.Z = 0.f;

			// follow water surface
			const FVector ToWaterSurfaceDelta = FVector(0.f, 0.f, MoveComp.WaterSurfaceZ.Value - WaternadoPos.Z);
			AddActorWorldOffset(ToWaterSurfaceDelta);
		}

		const float ToPlayerDistance = ToPlayer.Size();

		if(ToPlayerDistance > SMALL_NUMBER)
		{
			const float DeltaMoveMagnitude = MoveComp.GetAttackSpeed() * Dt;
			const float DeltaMoveMagClamped = FMath::Clamp(DeltaMoveMagnitude, 0.f, ToPlayerDistance);

			const FVector ToPlayerNormalized = ToPlayer / ToPlayerDistance;
			const FVector DeltaMove = ToPlayerNormalized * DeltaMoveMagClamped;

			AddActorWorldOffset(DeltaMove);
		}
	}

	bool bHasPlayedTornadoCloseVO = false;

	void UpdateVO() 
	{
		if (PlayerVictim == nullptr)
			return;

		// play VO when nado gets close enough to the player it is pursuing
		const float DistToVictimSQ = DistanceToPlayerSQ[PlayerVictim == Game::May ? Game::May : Game::Cody];
		if (DistToVictimSQ < FMath::Square(EnableAttackRadius * 0.5f))
		{
			if(!bHasPlayedTornadoCloseVO)
			{
				if (PlayerVictim.IsMay())
					PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeBoatTornadoCloseMay", Game::May);
				else
					PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeBoatTornadoCloseCody", Game::Cody);
				bHasPlayedTornadoCloseVO = true;
			}
		}
		else
		{
			bHasPlayedTornadoCloseVO = false;
		}
	}

	UFUNCTION(NetFunction)
	void NetEndPlayerAttack()
	{
		PlayerVictim = nullptr;
		MoveComp.EndPlayerAttackMovement();
		TimeStampEndPlayerAttack = Time::GetGameTimeSeconds();
		bHasPlayedTornadoCloseVO = false;
		WorldCameraShakeComp.Stop(false);
//		Print("End player attack");
	}

	bool CanAttackPlayer(AHazePlayerCharacter InPlayer) const
	{
		if(IsAttackOnCooldown())
			return false;

		return !UWaternadoPlayerResponseComponent::GetOrCreate(InPlayer).bNadoSkydiving;
	}

	bool IsAttackOnCooldown() const
	{
		return GetTimeSincePlayerWasAttacked() <= AttackPlayerCooldown;
	}

	float GetTimeSincePlayerWasAttacked() const
	{
		return Time::GetGameTimeSince(TimeStampEndPlayerAttack);
	}

	void DrawDebugPlayerAtack(bool bRunTime = false)
	{
		if(bRunTime == false)
		{
			if(bDebugPlayerAttackInEditor != bPrevDebugPlayerAttackInEditor)
			{
				System::FlushPersistentDebugLines();
				bPrevDebugPlayerAttackInEditor = bDebugPlayerAttackInEditor;
			}


			if(bDebugPlayerAttackInEditor)
			{
				System::FlushPersistentDebugLines();

				const float DebugSize = 50.f;
				const float DebugDrawTime = 2.f;

				System::DrawDebugCircle(GetActorLocation(), EnableAttackRadius, 32, FLinearColor::Red, DebugDrawTime, DebugSize, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugCircle(GetActorLocation(), DisableAttackRadius, 32, FLinearColor::LucBlue, DebugDrawTime, DebugSize, FVector::ForwardVector, FVector::RightVector);

				//MoveComp.DebugDrawDisableAttackRadius();

				// Draw same for overlapping nados
				TArray<AWaternado> DebugNados;
				GetAllActorsOfClass(DebugNados);
				const float OurMaxDebugDist = FMath::Max(EnableAttackRadius, DisableAttackRadius);
				for (int i = DebugNados.Num() - 1; i >= 0 ; i--)
				{
					if(DebugNados[i] == this)
						continue;

					const FVector DebugNadoPos = DebugNados[i].GetActorLocation(); 
					const float TheirMaxDebugDist = FMath::Max(DebugNados[i].EnableAttackRadius, DebugNados[i].DisableAttackRadius);
					const float DistBetweenNados = DebugNadoPos.Distance(GetActorLocation()); 
					const float CombinedThreshold = OurMaxDebugDist + TheirMaxDebugDist;

					if( DistBetweenNados < CombinedThreshold)
					{
						System::DrawDebugCircle(DebugNadoPos, DebugNados[i].EnableAttackRadius, 32, FLinearColor::Red, DebugDrawTime, DebugSize, FVector::ForwardVector, FVector::RightVector);
						System::DrawDebugCircle(DebugNadoPos, DebugNados[i].DisableAttackRadius, 32, FLinearColor::LucBlue, DebugDrawTime, DebugSize, FVector::ForwardVector, FVector::RightVector);
					}
				}
			}

		}
		else if (bDebugPlayerAttackInRuntime)
		{

			//System::FlushPersistentDebugLines();
			if(IsOutsideOfAttackRange())
			{
				const float DebugSize = 40.f;
				PrintToScreen(GetName() + " will not attack because it is outside of the Start Range", 0.f, FLinearColor::White);
				System::DrawDebugCircle(GetActorLocation(), EnableAttackRadius, 32, FLinearColor::White, 0.f, DebugSize, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugCircle(MoveComp.StartLocation, DisableAttackRadius, 32, FLinearColor::White, 0.f, DebugSize, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugLine(MoveComp.StartLocation, GetActorLocation(), FLinearColor::White, 0.f, DebugSize);
			}
			else
			{
				const float DebugSize = 20.f;
				FLinearColor DebugAttackColor = PlayerVictim == nullptr ? FLinearColor::Red : FLinearColor::Green;

				if(PlayerVictim != nullptr)
					System::DrawDebugLine(GetActorLocation(), PlayerVictim.GetActorLocation(), FLinearColor::Green, 0.f, DebugSize);

				System::DrawDebugCircle(GetActorLocation(), EnableAttackRadius, 32, DebugAttackColor, 0.f, DebugSize, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugCircle(MoveComp.StartLocation, DisableAttackRadius, 32, FLinearColor::LucBlue, 0.f, DebugSize, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugLine(MoveComp.StartLocation, GetActorLocation(), FLinearColor::LucBlue, 0.f, DebugSize);
			}
		}

	}

}