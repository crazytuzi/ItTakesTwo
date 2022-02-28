
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmGentlemanComponent;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourStates;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.UserGrindComponent;

event void FVictimHit(AHazePlayerCharacter PlayerVictim);

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmVictimComponent : UActorComponent
{
	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FVictimHit OnVictimHitBySwarm;

	UPROPERTY(BlueprintReadWrite, Category = "Victim Component")
	EHazePlayer BeginPlayVictim = EHazePlayer::May;

	// How large the impulse should be in fwd, right, up.
	// The direction itself is automatically calculated in the capability
	// !!! Will not be applied when airborne
	UPROPERTY(BlueprintReadWrite, Category = "Victim Component")
	FVector KnockdownMagnitude = FVector(500.f, 0.f, 1200.f);

	// How much dmg the player takes when getting hit by the swarm
	UPROPERTY(BlueprintReadWrite, Category = "Victim Component")
	float AttackDamage = 0.5f;

	// mainly used in the swarm Poseable
	// !! block the capability tag if you want to ensure it never damages the victim!! 
	UPROPERTY(Category = "Victim Component")
	bool bCanAlwaysAttackVictim = false;

	// How often we should update the nearest player. 
	float TimebetweenUpdates = 1.f;

	// Will trigger Capability to perform a search.
	// (Will be set to false once search is done)
	UPROPERTY(BlueprintReadWrite, NotVisible, Transient)
	bool bClearActivePlayerOverride = false;

	// Used to explicitly tell the capability 
	// that this is the player we want to have as victim.
	UPROPERTY(BlueprintReadWrite, NotVisible, Transient)
	TArray<FSwarmOverrideClosestPlayer> ClosestPlayerOverrides;

	// Do not set this manually! Use  
	UPROPERTY(BlueprintReadWrite, NotVisible, Transient)
	AHazePlayerCharacter CurrentVictim = nullptr;

	// Current override saved for comparison reasons
//	FSwarmOverrideClosestPlayer CurrentOverride;

	// Anim notifies will use this bool to communicate with capabilities.
	UPROPERTY(BlueprintReadWrite, NotVisible, Transient)
	bool bCanAttackVictim = false;

	bool bWasHeadingForwardsOnSpline = false;

	AHazeActor HazeOwner = nullptr;

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayerVictim() const property
	{
		return CurrentVictim;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(GetOwner());
		CurrentVictim = BeginPlayVictim == EHazePlayer::May ? Game::GetMay() : Game::GetCody();
	}

	FRotator GetVictimLookingRotator() const  property
	{
		if (CurrentVictim == nullptr)
			FRotator::ZeroRotator;
		return CurrentVictim.GetControlRotation();
	}

	FRotator GetVictimLookingRotatorYAWOnly() const property
	{
		FRotator TempRot = GetVictimLookingRotator();
		TempRot.Pitch = 0.f;
		TempRot.Roll = 0.f;
		TempRot.Normalize();
		return TempRot;
	}

	FVector GetPredictedVictimLocation(const float Time) const
	{
		const auto VictimMoveComp = UHazeBaseMovementComponent::Get(CurrentVictim);
		return CurrentVictim.GetActorLocation() + VictimMoveComp.Velocity * Time;
	}

	FVector GetVictimGroundNormal() const property
	{
		auto VictimMoveComp = UHazeBaseMovementComponent::Get(CurrentVictim);
		const FHitResult& HitData = VictimMoveComp.Impacts.DownImpact;

		if (!HitData.bBlockingHit)
			return FVector::UpVector;

		return HitData.Normal;
	}

	float GetVictimCapsuleHalfHeight() const
	{
		if (CurrentVictim == nullptr)
			return 0.f;

		float DummyRadius = 0.f, HalfHeight = 0.f;
		CurrentVictim.GetCollisionSize(DummyRadius, HalfHeight);

		return HalfHeight;
	}

	FVector GetVictimLookingDirectionConstrainedToXY() const property
	{
		return GetVictimLookingDirection().VectorPlaneProject(FVector::UpVector).GetSafeNormal();
	}

	FVector GetVictimLookingDirection() const property
	{
		if (CurrentVictim == nullptr)
			FVector::ZeroVector;
		return CurrentVictim.GetControlRotation().Vector();
	}

	FTransform GetVictimCenterTransform() const property
	{
		if (CurrentVictim == nullptr)
			FTransform::Identity;

		FTransform PlayerVictimTransform = CurrentVictim.GetActorTransform();
		PlayerVictimTransform.SetTranslation(CurrentVictim.GetActorCenterLocation());
		return PlayerVictimTransform;
	}

	FTransform GetLastValidGroundTransform() const property
	{

#if TEST
		if(CurrentVictim == nullptr)
		{
			// the capability that uses this function needs 
			// to nullptr check for player victim!
			ensure(false);
			return FTransform::Identity;
		}
#endif

		FTransform VictimTransform = CurrentVictim.GetActorTransform();
		VictimTransform.SetLocation(GetLastValidGroundLocation());

		return VictimTransform;
	}

	FVector GetLastValidGroundLocation() const property
	{

#if TEST
		if(CurrentVictim == nullptr)
		{
			// the capability that uses this function needs 
			// to nullptr check for player victim!
			ensure(false);
			return FVector::ZeroVector;
		}
#endif

		auto VictimMoveComp = UHazeBaseMovementComponent::Get(CurrentVictim);
		return VictimMoveComp.GetLastGroundedLocation();
		// return VictimMoveComp.GetLastValidGround().ImpactPoint;
	}

	UFUNCTION()
	AHazePlayerCharacter GetClosestPlayerOverride() const property
	{
		if (ClosestPlayerOverrides.Num() != 0)
			return ClosestPlayerOverrides.Last().Player;
		return nullptr;
	}

	bool IsVictimAliveAndGrounded() const
	{
		return IsPlayerAliveAndGrounded(CurrentVictim);
	}

	bool IsOtherVictimAliveAndGrounded() const
	{
		return IsPlayerAliveAndGrounded(CurrentVictim.OtherPlayer);
	}

	bool IsPlayerAliveAndGrounded(AHazePlayerCharacter InPlayer) const 
	{
		if(InPlayer == nullptr)
			return false;

		auto HealthComp = UPlayerHealthComponent::Get(InPlayer); 
		if(HealthComp.bIsDead)
			return false;

		return IsPlayerGrounded(InPlayer, 1000.f);
	}

	bool IsVictimOverrideRequested() const
	{
		return ClosestPlayerOverrides.Num() != 0;
	}

	bool ShouldApplyVictimOverride() const
	{
		if (ClosestPlayerOverrides.Num() == 0)
			return false;

		const FSwarmOverrideClosestPlayer& LatestOverrideRequest = ClosestPlayerOverrides.Last();

		return CurrentVictim != LatestOverrideRequest.Player;
	}

	bool IsOverrideClosestPlayerActive(UObject OptionalInstigator = nullptr) const
	{
		if(OptionalInstigator != nullptr)
		{
			for (int i = ClosestPlayerOverrides.Num() - 1; i >= 0; --i)
			{
				if (ClosestPlayerOverrides[i].Instigator == OptionalInstigator)
				{
					return true;
				}
			}
		}
		else
		{
			return ClosestPlayerOverrides.Num() > 0;
		}

		return false;
	}

	UFUNCTION()
	void OverrideClosestPlayer(
		AHazePlayerCharacter InPlayerOverride,
		UObject InInstigator
	)
	{
		ensure(InPlayerOverride != nullptr);
		ensure(InInstigator != nullptr);

		// only allow 1 override per Instigator
		RemoveClosestPlayerOverride(InInstigator);

		FSwarmOverrideClosestPlayer NewEntry;
		NewEntry.Player = InPlayerOverride;
		NewEntry.Instigator = InInstigator;

		ClosestPlayerOverrides.Add(NewEntry);
	}

	UFUNCTION()
	void RemoveClosestPlayerOverride(UObject InInstigator)
	{
		if (ClosestPlayerOverrides.Num() == 0)
			return;

		for (int i = ClosestPlayerOverrides.Num() - 1; i >= 0; --i)
		{
			if (ClosestPlayerOverrides[i].Instigator == InInstigator)
			{
				ClosestPlayerOverrides.RemoveAt(i);

				// we can early out because we only allow 1 override per instigator
				break;
			}
		}
	}

	void ClearAllPlayerOverride()
	{
		ClosestPlayerOverrides.Reset();
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

	/* Returns the player closest to the swarm within the SearchForPlayerRadius */
	AHazePlayerCharacter FindClosestLivingPlayerWithinRange(const float SearchForPlayerRadius = 150000.f) const
	{
		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		const UPlayerHealthComponent MayHPComp = UPlayerHealthComponent::Get(May);
		const UPlayerHealthComponent CodyHPComp = UPlayerHealthComponent::Get(Cody);

		if (MayHPComp == nullptr && CodyHPComp == nullptr)
			return nullptr;

		const bool bAlive_May = MayHPComp.bIsDead == false;
		const bool bAlive_Cody = CodyHPComp.bIsDead == false;

		const FVector SwarmLocation = GetOwner().GetActorLocation();
		const FVector MayLocation = May.GetActorLocation();
		const FVector CodyLocation = Cody.GetActorLocation();

		const float DistSQ_Cody = (SwarmLocation - CodyLocation).SizeSquared();
		const float DistSQ_May = (SwarmLocation - MayLocation).SizeSquared();
		const float SearchForPlayerRadiusSQ = FMath::Square(SearchForPlayerRadius);

		if(bAlive_Cody && bAlive_May)
		{
			if(DistSQ_May < DistSQ_Cody && DistSQ_May < SearchForPlayerRadiusSQ)
			{
				return May;
			}
			else if(DistSQ_Cody < SearchForPlayerRadiusSQ)
			{
				return Cody;
			}
		}
		else if(bAlive_May && DistSQ_May < SearchForPlayerRadiusSQ)
		{
			return May;
		}
		else if(bAlive_Cody && DistSQ_Cody < SearchForPlayerRadiusSQ)
		{
			return Cody;
		}

		return nullptr;
	}

	bool IsVictimFollowingSpline() const
	{
		auto Comp = GetSplineFollowComp();
		return Comp == nullptr ? false : Comp.HasActiveSpline();
	}

	UHazeSplineFollowComponent GetSplineFollowComp() const
	{
		return UHazeSplineFollowComponent::Get(CurrentVictim);
	}

	float DistanceToVictim() const 
	{
		if (CurrentVictim == nullptr)
			return 0.f;
		return (HazeOwner.GetActorLocation() - CurrentVictim.GetActorLocation()).Size();
	}

	float DistanceToVictimSQ() const 
	{
		if (CurrentVictim == nullptr)
			return BIG_NUMBER;
		return (HazeOwner.GetActorLocation() - CurrentVictim.GetActorLocation()).SizeSquared();
	}

	// checks if the current victim is close enough 
	UFUNCTION(BlueprintPure)
	bool IsVictimWithinRadius(float Radius) 
	{
		if (CurrentVictim == nullptr)
			return false;

		const FVector VictimPos = CurrentVictim.GetActorLocation();
		const FVector SwarmPos = GetOwner().GetActorLocation();
		const float DistBetween_SQ = (VictimPos - SwarmPos).SizeSquared();
		return DistBetween_SQ < FMath::Square(Radius);
	}

	bool IsPlayerGrinding(AHazePlayerCharacter InPlayer) const
	{
		const bool bGrindMovement = InPlayer.IsAnyCapabilityActive(GrindingCapabilityTags::Movement); 
		if(bGrindMovement)
			return true;

		const bool bGrindEval = InPlayer.IsAnyCapabilityActive(GrindingCapabilityTags::Evaluate); 
		if(!bGrindEval)
			return false;

		// player is on the ground and evaluating. He isn't grinding yet. 
		auto PlayerMoveComp = UHazeBaseMovementComponent::Get(InPlayer);
		if(PlayerMoveComp.IsGrounded())
			return false;

		// const bool bTrulyGrounded = IsVictimGrounded(1000.f);

		/* 	We want to ensure that the swarm doesn't ping pong 
			between states when the player does.  */
		UUserGrindComponent GrindComp = UUserGrindComponent::Get(InPlayer);
		if(GrindComp.GetTimeSinceGrindingStopped() < 5.f)
		{
			// Player is airborne and stopped grinding not so long ago... 
			// We'll treat that as grinding still
			return true;
		}

		return false;
	}

	bool IsVictimGrinding() const
	{
		return IsPlayerGrinding(CurrentVictim);
	}

	// bool IsVictimGrounded() const
	bool IsVictimGrounded(const float InTraceDistance = -1.f) const
	{
		if(CurrentVictim == nullptr)
			return false;

		return IsPlayerGrounded(CurrentVictim, InTraceDistance);
	}

	bool IsPlayerGrounded(AHazePlayerCharacter InPlayer, const float InTraceDistance = -1.f) const
	{
		auto PlayerMoveComp = UHazeBaseMovementComponent::Get(InPlayer);
		if(PlayerMoveComp.IsGrounded())
			return true;
		
		if(InTraceDistance > 0.f)
		{
			FHitResult HitData;

			TArray<AActor> IgnoreActors; 
			IgnoreActors.Add(Game::GetMay());
			IgnoreActors.Add(Game::GetCody());

			const FVector PlayerCenter = InPlayer.GetActorCenterLocation();

			const bool bHit = System::LineTraceSingle(
				PlayerCenter,
				PlayerCenter - FVector::UpVector * InTraceDistance,
				ETraceTypeQuery::Visibility,
				false,
				IgnoreActors,
				EDrawDebugTrace::None,
				HitData,
				true
			);

			return bHit;
		}

		return false;
	}

	FVector GetTowardsVictim() const
	{
		if(CurrentVictim == nullptr)
			return FVector::ZeroVector;

		return (CurrentVictim.GetActorLocation() - Owner.GetActorLocation());
	}

	// external manager will update this on all swarms.
	private bool bUseSharedGentlemanComp = false;

	void ActivateSharedGentlemanBehaviour()
	{
		const bool bWasUsingSharedGentlemanComp = bUseSharedGentlemanComp;
		bUseSharedGentlemanComp = true;

		if(!bWasUsingSharedGentlemanComp)
		{
			if(CurrentVictim == Game::GetCody())
			{
				ClearAllClaimsForPlayer(Game::GetCody());
				ClearAllClaimsForPlayer(Game::GetMay());
			}
			else if(CurrentVictim == Game::GetMay())
			{
				USwarmGentlemanComponent GentlemanComp_May = USwarmGentlemanComponent::GetOrCreate(CurrentVictim);
				TArray<FName> ClaimedTags;
				GentlemanComp_May.GetAllActionSemaphoreTags(ClaimedTags);
				for(const FName IterClaimedTag : ClaimedTags)
				{
					if(GentlemanComp_May.IsClaimingAction(IterClaimedTag, HazeOwner))
					{
						// reclaim now that shared gentleman is active
						ClaimPlayer(CurrentVictim, IterClaimedTag);
					}
				}
			}
		}

	}

	void DeactivateSharedGentlemanBehaviour()
	{
		if (bUseSharedGentlemanComp)
		{
			if(CurrentVictim == Game::GetMay())
			{
				ClearAllClaimsForPlayer(Game::GetCody());
			}
			else if(CurrentVictim == Game::GetCody())
			{
				ClearAllClaimsForPlayer(Game::GetMay());
			}
		}

		bUseSharedGentlemanComp = false;
	}

	bool IsUsingSharedGentlemanBehaviour() const
	{
		return bUseSharedGentlemanComp;
	}

	int GetNumSwarmOpponents() const
	{
		USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(CurrentVictim);
		if(bUseSharedGentlemanComp)
		{
			USwarmGentlemanComponent OtherGentlemanComp = USwarmGentlemanComponent::GetOrCreate(CurrentVictim.OtherPlayer);
			return (GentlemanComp.Opponents.Num() + OtherGentlemanComp.Opponents.Num() );
		}
		else
		{
			return GentlemanComp.Opponents.Num();
		}

	}

	bool IsGentlemaning(int& OutGentlemanIndex)
	{

		if(bUseSharedGentlemanComp)
		{
			AHazePlayerCharacter May = Game::GetMay();
			AHazePlayerCharacter Cody = Game::GetCody();
			USwarmGentlemanComponent GentlemanComp_May = USwarmGentlemanComponent::GetOrCreate(May);
			USwarmGentlemanComponent GentlemanComp_Cody = USwarmGentlemanComponent::GetOrCreate(Cody);

			const int SumOpponents = GentlemanComp_May.Opponents.Num() + GentlemanComp_Cody.Opponents.Num();

			if(SumOpponents <= 1)
				return false;

			if(GentlemanComp_May.Opponents.Num() >= 1)
			{
				OutGentlemanIndex = GentlemanComp_May.Opponents.FindIndex(HazeOwner);
				if(OutGentlemanIndex != -1)
				{
					// PrintScaled(Owner.GetName() + " GentlemanIndex: " + OutGentlemanIndex, 0.f, FLinearColor::Yellow, 2.f);
					return true;
				}
				else if(GentlemanComp_Cody.Opponents.Num() >= 1)
				{
					OutGentlemanIndex = GentlemanComp_Cody.Opponents.FindIndex(HazeOwner);
					if(OutGentlemanIndex != -1)
					{
						// this is perhaps needed when we have more then 2 swarms. But we don't have that, so
						// OutGentlemanIndex = GentlemanComp_May.Opponents.Num() + OutGentlemanIndex;
						// PrintScaled(Owner.GetName() + " GentlemanIndex: " + OutGentlemanIndex, 0.f, FLinearColor::Yellow, 2.f);
						return true;
					}
				}
			}
			else if(GentlemanComp_Cody.Opponents.Num() >= 1)
			{
				OutGentlemanIndex = GentlemanComp_Cody.Opponents.FindIndex(HazeOwner);
				if(OutGentlemanIndex != -1)
				{
					// PrintScaled(Owner.GetName() + " GentlemanIndex: " + OutGentlemanIndex, 0.f, FLinearColor::Yellow, 2.f);
					return true;
				}
			}
		}
		else
		{
			USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(CurrentVictim);
			if(GentlemanComp.Opponents.Num() > 1)
			{
				OutGentlemanIndex = GentlemanComp.Opponents.FindIndex(HazeOwner);
				return OutGentlemanIndex != -1;
			}
		}

		return false;
	}

	void ClearAllClaimsForPlayer(AHazePlayerCharacter InPlayer) 
	{
		USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		GentlemanComp.ClearClaimantFromAllSemaphores(HazeOwner);
	}
	
	void ResetGentlemanForPlayer(AHazePlayerCharacter InPlayer) 
	{
		USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		GentlemanComp.ClearClaimantFromAllSemaphores(HazeOwner);
		GentlemanComp.Opponents.Remove(HazeOwner);
	}

	void ResetGentlemanBehaviour()
	{
		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		ResetGentlemanForPlayer(May);
		ResetGentlemanForPlayer(Cody);
	}

	void UnclaimVictim(FName Tag)
	{
		if(bUseSharedGentlemanComp)
			UnclaimBothPlayers(Tag);
		else
			UnclaimPlayer(Tag, CurrentVictim);
	}

	void UnclaimBothPlayers(FName Tag)
	{
		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		UnclaimPlayer(Tag, May);
		UnclaimPlayer(Tag, Cody);
	}

	void UnclaimPlayer(FName Tag, AHazePlayerCharacter InPlayer)
	{
		if(bUseSharedGentlemanComp)
		{
			UnClaimShared(Tag);
			return;
		}

		// We'll use the players actor channel for claiming
		if (InPlayer.HasControl() == false)
			return;

		auto GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		GentlemanComp.NetUnclaimAction(Tag, HazeOwner);
	}

	void UnClaimShared(FName Tag)
	{
		// We'll use mays actor channel for shared claiming/unclaiming
		AHazePlayerCharacter May = Game::GetMay();

		if(May.HasControl() == false)
			return;

		AHazePlayerCharacter Cody = Game::GetCody();

		USwarmGentlemanComponent GentlemanComp_May = USwarmGentlemanComponent::GetOrCreate(May);
		GentlemanComp_May.NetUnclaimAction(Tag, HazeOwner);

		USwarmGentlemanComponent GentlemanComp_Cody = USwarmGentlemanComponent::GetOrCreate(Cody);
		GentlemanComp_Cody.NetUnclaimAction(Tag, HazeOwner);
	}

	void ClaimShared(FName Tag, int MaxAllowed = 1)
	{
		AHazePlayerCharacter May = Game::GetMay();

		if(May.HasControl() == false)
			return;

		if(!IsClaimable(Tag, May))
			return;

		if(IsClaiming(Tag, May))
			return;

		USwarmGentlemanComponent GentlemanComp_May = USwarmGentlemanComponent::GetOrCreate(May);
		const bool bClaimedMay = GentlemanComp_May.NetClaimAction(Tag, HazeOwner, MaxAllowed);

		AHazePlayerCharacter Cody = Game::GetCody();
		USwarmGentlemanComponent GentlemanComp_Cody = USwarmGentlemanComponent::GetOrCreate(Cody);
		const bool bClaimedCody = GentlemanComp_Cody.NetClaimAction(Tag, HazeOwner, MaxAllowed);

		ensure(bClaimedMay && bClaimedCody);
	}

	void ClaimPlayer(AHazePlayerCharacter InPlayer, FName InTag, int InMaxAllowed = 1)
	{
		if(bUseSharedGentlemanComp)
		{
			ClaimShared(InTag, InMaxAllowed);
			return;
		}

		// We'll use the players actor channel for claiming
		if (InPlayer.HasControl() == false)
			return;

		if(!IsClaimable(InTag, InPlayer))
			return;

		if(IsClaiming(InTag, InPlayer))
			return;

		USwarmGentlemanComponent GentlemanComp= USwarmGentlemanComponent::GetOrCreate(InPlayer);
		const bool bPlayerClaimed = GentlemanComp.NetClaimAction(InTag, HazeOwner, InMaxAllowed);

		// Print("Claim!!" + Tag, 3.f);

		if(bPlayerClaimed)
		{
			USwarmGentlemanComponent OtherGentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer.OtherPlayer);
			if(bUseSharedGentlemanComp)
			{
				const bool bClaimedOther = OtherGentlemanComp.NetClaimAction(InTag, HazeOwner, InMaxAllowed);

				// we weren't able to claim both players. Please let Sydney know if this triggers
				ensure(bPlayerClaimed == bClaimedOther);
			}
			else if(OtherGentlemanComp.IsClaimingAction(InTag, HazeOwner))
			{
				OtherGentlemanComp.NetUnclaimAction(InTag, HazeOwner);
			}
		}

	}

	bool IsClaimable(FName Tag, AHazePlayerCharacter InPlayer) const
	{
		USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		const bool bIsClaimingPlayer = GentlemanComp.IsClaimingAction(Tag, HazeOwner); 

		if(bUseSharedGentlemanComp)
		{
			USwarmGentlemanComponent OtherGentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer.OtherPlayer);
			const bool bIsClaimingOtherPlayer = OtherGentlemanComp.IsClaimingAction(Tag, HazeOwner); 
			const bool bCanClaimPlayer = GentlemanComp.IsActionAvailable(Tag);
			const bool bCanClaimOtherPlayer = OtherGentlemanComp.IsActionAvailable(Tag);

			if(bIsClaimingPlayer && (bIsClaimingOtherPlayer || bCanClaimOtherPlayer))
			{
				return true;
			}
			else if(bIsClaimingOtherPlayer && (bIsClaimingPlayer || bCanClaimPlayer))
			{
				return true;
			}
			else 
			{
				return (bCanClaimPlayer && bCanClaimOtherPlayer);
			}
		}
		else
		{
			if(bIsClaimingPlayer)
				return true;
			else
				return GentlemanComp.IsActionAvailable(Tag);
		}
	}

	bool IsClaiming(FName Tag, AHazePlayerCharacter InPlayer) const
	{
		USwarmGentlemanComponent GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		const bool bIsClaimingPlayer = GentlemanComp.IsClaimingAction(Tag, HazeOwner); 

		if(bUseSharedGentlemanComp)
		{
			USwarmGentlemanComponent OtherGentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer.OtherPlayer);
			const bool bIsClaimingOtherPlayer = OtherGentlemanComp.IsClaimingAction(Tag, HazeOwner); 
			return (bIsClaimingPlayer && bIsClaimingOtherPlayer);
		}
		else
		{
			return bIsClaimingPlayer;
		}
	}

	bool HasVictimBeenClaimedByAnyone() const
	{
		return HasPlayerBeenClaimedByAnyone(CurrentVictim);
	}

	bool HasOtherVictimBeenClaimedByAnyone() const
	{
		return HasPlayerBeenClaimedByAnyone(CurrentVictim.OtherPlayer);
	}

	bool HasPlayerBeenClaimedByAnyone(AHazePlayerCharacter InPlayer) const
	{
		auto GentlemanComp = USwarmGentlemanComponent::GetOrCreate(InPlayer);
		return GentlemanComp.HasBeenClaimed();
	}

	AHazePlayerCharacter GetOtherVictim() const
	{
		if (CurrentVictim == nullptr)
			return nullptr;

		return CurrentVictim.OtherPlayer;
	}

}

struct FSwarmOverrideClosestPlayer 
{
	UPROPERTY(BlueprintReadWrite)
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY(BlueprintReadWrite)
	UObject Instigator = nullptr;

	FSwarmOverrideClosestPlayer(
		AHazePlayerCharacter InOverrideVictim,
		UObject InInstigator
	)
	{
		Player = InOverrideVictim;
		Instigator = InInstigator;
	}

	bool Equals(const FSwarmOverrideClosestPlayer& InOverride) const
	{
		if (Player != InOverride.Player)
			return false;

		return true;
	}

	// These don't work at the c++ level. 
//	bool opEquals(const FSwarmOverrideClosestPlayer& Other) const
//	{
//		return Instigator == Other.Instigator;
//	}
//
//	bool opEquals(FSwarmOverrideClosestPlayer& Other) const
//	{
//		return Instigator == Other.Instigator;
//	}

};

