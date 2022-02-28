
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailSocketDefinition;
import Vino.Movement.Components.MovementComponent;
import Vino.SwingBar.SwingBarActor;
import Vino.Pierceables.PierceStatics;

/**
 * Common place for the Nail capabilities (and BP stuff)
 */

event void FNailEquippedEventSignature(AHazeActor Weapon);
event void FNailUnequippedEventSignature(AHazeActor Weapon);

UCLASS(HideCategories = "Cooking Collision ComponentReplication Sockets Tags Sockets")
class UNailWielderComponent : UActorComponent 
{
	/*
		!!! Make sure to reset all new variables in this function !!!

		We use this function because we are not allowed
		to destroy components manually, in network, in between player resets. 

		(Due to components having their network identifier on the player, which resets during the player reset)
	*/
	void Reset()
	{
		OnNailEquipped.Clear();
		OnNailUnequipped.Clear();
		NailsEquippedToBack.Empty();
		NailEquippedToHand = nullptr;
		NailsThrown.Empty();
		NailsBeingRecalled.Empty();
		NailRecallQueue.Empty();
		EquippedNailCount = 0;
		bAiming = false;
		WiggleTime = 0.32f;

		// reseting this network identifier is probably not needed and it might be risky. Needs testing.
		// SpawnedNailCount = 0;
		// Player = nullptr;
	}

	UPROPERTY()
	UStaticMeshComponent NailHolster;

	/* When the nail weapon is equipped on the character. (Also trigger on recalls) */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailEquippedEventSignature OnNailEquipped;
		
	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNailUnequippedEventSignature OnNailUnequipped;

 	/* Nails on back only. */
	UPROPERTY()
	TArray<ANailWeaponActor> NailsEquippedToBack;

	/* Nail taken from the NailsEquippedToBack Pool */
	UPROPERTY()
	ANailWeaponActor NailEquippedToHand;

	/* reference to all Weapon actors we've unequipped (thrown away) */
	UPROPERTY()
	TArray<ANailWeaponActor> NailsThrown;

	/* Nails currently being recalled. */
	UPROPERTY(NotEditable)
	TArray<FNailRecallData> NailsBeingRecalled;

	UPROPERTY(NotEditable)
	TArray<ANailWeaponActor> NailRecallQueue;

	UPROPERTY(BlueprintReadOnly)
	bool bAiming = false;

	AHazePlayerCharacter Player;

	/*  Nails will be assigned an Index by the wielderComponent.
		In order for them to know which of the 4 different unique
		animations / sounds / effects / return paths they should use. */
	int EquippedNailCount = 0;

	// network identifier
	int SpawnedNailCount = 0;

	float WiggleTime = 0.32f;
	float RecallTagUnblockedCooldown = 2.f;
	float TimeStampRecallTagUnblocked = 0.f;

	// Transients
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	bool AreNailsBeingRecalled() const
	{
		return NailsBeingRecalled.Num() > 0;
	}

	bool IsRecallCooldownActive() const
	{
		return Time::GetGameTimeSince(TimeStampRecallTagUnblocked) < RecallTagUnblockedCooldown;
	}

	// -1 means not found
	int GetNailBeingRecalledIndex(ANailWeaponActor InNail) const
	{
		for (int i = 0; i < NailsBeingRecalled.Num(); ++i)
		{
			if (InNail == NailsBeingRecalled[i].Nail)
			{
				return i;
			}
		}
		return -1;
	}

	bool AreThrownNailsRenderedFor(AHazePlayerCharacter InPlayer) const 
	{
		for(const ANailWeaponActor NailIter : NailsThrown)
		{
			if(SceneView::IsInView(InPlayer, NailIter.GetActorLocation()))
			{
				return true;
			}
		}
		return false;
	}

	void ThrowNail(ANailWeaponActor InNail, FNailTargetData InTargetData, const float ImpulseMagnitude)
	{
		ensure(InNail != nullptr);

		const bool bPierced = IsPierced(InNail);
		ensure(!bPierced);

		// FHazeCameraImpulse Impulse;
		// Impulse.CameraSpaceImpulse = FVector(-1200.f, 0.f, 0.f);
		// Impulse.ExpirationForce = 140.f;
		// Impulse.Dampening = 0.5f;
		// Player.ApplyCameraImpulse(Impulse, this);

		InNail.LaunchNail(InTargetData, ImpulseMagnitude);

		UHazeMovementComponent MoveComp = UHazeMovementComponent::GetOrCreate(Player);

		MoveComp.SetAnimationToBeRequested(n"NailThrow");
		SetAnimBoolParam(InNail, n"NailThrow", true);

		if(GetNumNailsEquipped() <= 0)
			SetAnimBoolParam(InNail, n"NoNailsEquipped", true);
	}

	bool IsRecallingSingleNail() const
	{
		return NailsBeingRecalled.Num() != 0;
	}

	bool IsRecallingAllNails() const
	{
		return GetNumNailsOwnedByWielder() == NailsBeingRecalled.Num();
	}
	
	UFUNCTION()
	void SetAnimBoolParam(ANailWeaponActor InNail, FName Tag, bool Value)
	{
		Player.SetAnimBoolParam(Tag, Value);
		if(InNail != nullptr)
			InNail.SetAnimBoolParam(Tag, Value);
	}

	void SetAnimFloatParam(ANailWeaponActor InNail, FName Tag, float Value)
	{
		Player.SetAnimFloatParam(Tag, Value);
		if(InNail != nullptr)
			InNail.SetAnimFloatParam(Tag, Value);
	}

	void SetAnimIntParam(ANailWeaponActor InNail, FName Tag, int Value)
	{
		Player.SetAnimIntParam(Tag, Value);
		if(InNail != nullptr)
			InNail.SetAnimIntParam(Tag, Value);
	}

	UFUNCTION()
	void SetAnimBoolParamOnAll(FName Tag, bool Value)
	{
		TArray<ANailWeaponActor> AllNails;
		AllNails.Append(NailsThrown);
		AllNails.Append(NailsEquippedToBack);

		if(NailEquippedToHand != nullptr)
			AllNails.AddUnique(NailEquippedToHand);
		
		for(FNailRecallData NailRecallData : NailsBeingRecalled)
			AllNails.AddUnique(NailRecallData.Nail);

		for(ANailWeaponActor Nail : AllNails)
			Nail.SetAnimBoolParam(Tag, Value);

		Player.SetAnimBoolParam(Tag, Value);
	}

	void SetAnimFloatParamOnAll(FName Tag, float Value)
	{
		TArray<ANailWeaponActor> AllNails;
		AllNails.Append(NailsThrown);
		AllNails.Append(NailsEquippedToBack);

		if(NailEquippedToHand != nullptr)
			AllNails.AddUnique(NailEquippedToHand);
		
		for(FNailRecallData NailRecallData : NailsBeingRecalled)
			AllNails.AddUnique(NailRecallData.Nail);

		for(ANailWeaponActor Nail : AllNails)
			Nail.SetAnimFloatParam(Tag, Value);

		Player.SetAnimFloatParam(Tag, Value);
	}

	void SetAnimIntParamOnAll(FName Tag, float Value)
	{
		TArray<ANailWeaponActor> AllNails;
		AllNails.Append(NailsThrown);
		AllNails.Append(NailsEquippedToBack);

		if(NailEquippedToHand != nullptr)
			AllNails.AddUnique(NailEquippedToHand);
		
		for(FNailRecallData NailRecallData : NailsBeingRecalled)
			AllNails.AddUnique(NailRecallData.Nail);

		for(ANailWeaponActor Nail : AllNails)
			Nail.SetAnimIntParam(Tag, Value);

		Player.SetAnimIntParam(Tag, Value);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
		if(NailHolster != nullptr)
		{
			bool bRemovedMesh = Player.RemoveStaticMesh(NailHolster.StaticMesh);
			while(bRemovedMesh && NailHolster != nullptr)
				bRemovedMesh = Player.RemoveStaticMesh(NailHolster.StaticMesh);
			NailHolster = nullptr;
		}

		TArray<ANailWeaponActor> AllNails;
		AllNails.Append(NailsThrown);
		AllNails.Append(NailsEquippedToBack);
		AllNails.AddUnique(NailEquippedToHand);
		
		for(FNailRecallData NailRecallData : NailsBeingRecalled)
			AllNails.AddUnique(NailRecallData.Nail);

		for(ANailWeaponActor Nail : AllNails)
		{
			if (Nail != nullptr && Nail.IsActorBeingDestroyed() == false)
			{
				Nail.DestroyActor();
			}
		}

    }

	UFUNCTION(Category = "Weapon|Nail")
	void SwitchNailAttachSocket(ANailWeaponActor InNailWeapon, ENailSocketDefinition InSocket)
	{
		if (InNailWeapon == nullptr)
		{
			ensure(false);
			return;
		}
		
		const AHazeActor CurrentWielder = InNailWeapon.GetWielder();
		if (CurrentWielder != Owner)
		{
			ensure(false);
			return;
		}

		InNailWeapon.AttachToActor(
			Owner,
			GetNailSocketNameFromDefinition(InSocket),
			EAttachmentRule::SnapToTarget
		);
	}

	void EquipNailToHand(ANailWeaponActor NailToBeEquippedToHand)
	{
		if (NailToBeEquippedToHand == nullptr)
		{
			PrintError("EquipNailToHand() failed. NailToBeEquippedToHand == nullptr");
			ensure(false);
			return;
		}

		ensure(!NailsThrown.Contains(NailToBeEquippedToHand));

		ensure(NailEquippedToHand == nullptr || (NailEquippedToHand == NailToBeEquippedToHand));

		NailEquippedToHand = NailToBeEquippedToHand;
   		NailsEquippedToBack.Remove(NailToBeEquippedToHand);

		//SetAnimIntParam(NailEquippedToHand, n"PreviousAssignedIndex", NailEquippedToHand.AssignedIndex);
		//NailEquippedToHand.AssignedIndex = NailsEquippedToBack.FindIndex(NailEquippedToHand) + 1;	
		//SetAnimIntParam(NailEquippedToHand, n"AssignedIndex", NailEquippedToHand.AssignedIndex);

		SetAnimBoolParam(NailEquippedToHand, n"NailEquip", true);
		SetAnimBoolParam(NailEquippedToHand, n"NailEquippedToHand", true);

		SwitchNailAttachSocket(NailToBeEquippedToHand, ENailSocketDefinition::NailWeapon_HandThrow);
	}

	void UnequipNailFromHand() 
	{
		SwitchNailAttachSocket(NailEquippedToHand, ENailSocketDefinition::NailWeapon_Quiver);

 		NailsEquippedToBack.Add(NailEquippedToHand);

		// SetAnimIntParam(NailEquippedToHand, n"PreviousAssignedIndex", NailEquippedToHand.AssignedIndex);
		// NailEquippedToHand.AssignedIndex = NailsEquippedToBack.FindIndex(NailEquippedToHand) + 1;	
		//SetAnimIntParam(NailEquippedToHand, n"AssignedIndex", NailEquippedToHand.AssignedIndex);

		SetAnimBoolParam(NailEquippedToHand, n"NailUnequip", true);
		SetAnimBoolParam(NailEquippedToHand, n"NailEquippedToHand", false);

		NailEquippedToHand = nullptr;
	}

	void ForceFinishNailRecallForNail(ANailWeaponActor InNail)
	{
		const int NailBeingRecalledIndex = GetNailBeingRecalledIndex(InNail);
		if(NailBeingRecalledIndex != -1)
			ForceFinishNailRecall(NailBeingRecalledIndex);
		else
			NailRecallQueue.Remove(InNail);
	}

	void ForceFinishNailRecallForAllNails()
	{
		if(NailsBeingRecalled.Num() > 0)
		{
			for (int i = NailsBeingRecalled.Num() - 1; i >= 0 ; i--)
			{
				ForceFinishNailRecall(i);
			}
		}
	}

	void ForceFinishNailRecall(int NailRecallIndex)
	{
		FNailRecallData& RecallData = NailsBeingRecalled[NailRecallIndex];

		if(!RecallData.bFinishedWiggling)
			HandleWiggleFinished(RecallData);

		RecallData.DistanceToFly = KINDA_SMALL_NUMBER;
		RecallData.TimeUntilArrival = -1.f;

		auto MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		MoveComp.SetAnimationToBeRequested(n"NailCatch");
		SetAnimBoolParam(RecallData.Nail, n"NailCatch", true);

		EquipNailWeapon(RecallData.Nail, ENailSocketDefinition::NailWeapon_Quiver);
	}

	void EquipNailWeapon(
		ANailWeaponActor NailWeapon,
		ENailSocketDefinition InSocket = ENailSocketDefinition::NailWeapon_Quiver
	)
	{
		if (IsPierced(NailWeapon))
			UnpierceActors(NailWeapon);

		NailWeapon.OnNailPreCaughtEvent.Broadcast();

		NailWeapon.MovementComponent.Velocity = FVector::ZeroVector;

		// Per wanted to try out scaling the nail
		NailWeapon.SetActorScale3D(1.f);

		NailWeapon.Mesh.DisableAndCachePhysicsSettings();
		NailWeapon.StopSweeping();
		NailWeapon.AttachToActor(Owner, GetNailSocketNameFromDefinition(InSocket), EAttachmentRule::SnapToTarget);
		NailWeapon.SetWielder(Cast<AHazeActor>(Owner));
		NailWeapon.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", 0.f);
		AddNailWeapon(NailWeapon);
		NailWeapon.OnNailPostCaughtEvent.Broadcast();
	}

	UFUNCTION()
	void AddNailWeapon(ANailWeaponActor NailBeingAdded)
	{
		// Clean up stale references
		// NailsThrown.RemoveSwap(nullptr);
		// NailsEquippedToBack.RemoveSwap(nullptr);
		NailsThrown.Remove(nullptr);
		NailsEquippedToBack.Remove(nullptr);

		if (NailBeingAdded == nullptr)
		{
			devEnsure(false, ( "" + GetName() + "AddWeapon() failed. Input Weapon == null"));
			return;
		}

		if (NailsEquippedToBack.Contains(NailBeingAdded) || (NailEquippedToHand != nullptr && NailEquippedToHand == NailBeingAdded))
		{
			devEnsure(false, GetName() + "Trying to add " + NailBeingAdded.GetName() + " twice. The weapon is allready equipped");
			return;
		}

		for (int i = NailsBeingRecalled.Num() - 1; i >= 0 ; i--)
		{
			if(NailsBeingRecalled[i].Nail == NailBeingAdded)
				NailsBeingRecalled.RemoveAt(i);
		}

		NailRecallQueue.Remove(NailBeingAdded);
		NailsThrown.Remove(NailBeingAdded);

		NailsEquippedToBack.Add(NailBeingAdded);

		if(NailBeingAdded.Mesh.AssignedIndex == -1)
		{
			NailBeingAdded.Mesh.AssignedIndex = EquippedNailCount + 1;
			++EquippedNailCount;
		}

		SetAnimBoolParam(NailBeingAdded, n"NailEquip", true);
		OnNailEquipped.Broadcast(NailBeingAdded);
		NailBeingAdded.OnNailEquipped.Broadcast(Player);
	}

	UFUNCTION()
	void RemoveWeapon(ANailWeaponActor Weapon)
	{
		// Clean up stale references
		NailsThrown.Remove(nullptr);
		NailsEquippedToBack.Remove(nullptr);
		// NailsThrown.RemoveSwap(nullptr);
		// NailsEquippedToBack.RemoveSwap(nullptr);

		if (Weapon == nullptr)
		{
			devEnsure(false, GetName() + "RemoveWeapon() failed. Input Weapon == null");
			return;
		}

		if (NailsThrown.Contains(Weapon))
		{
			devEnsure(false, GetName() + "Trying to throw/remove " + Weapon.GetName() + " when its already been thrown/removed");
			return;
		}

		NailsThrown.Add(Weapon);

		if (NailEquippedToHand == Weapon) 
			NailEquippedToHand = nullptr;
		else 
			NailsEquippedToBack.Remove(Weapon);

		//SetAnimIntParam(Weapon, n"PreviousAssignedIndex", Weapon.AssignedIndex);
		//Weapon.AssignedIndex = NailsEquippedToBack.FindIndex(Weapon) + 1;	
		//SetAnimIntParam(Weapon, n"AssignedIndex", Weapon.AssignedIndex);

		SetAnimBoolParam(Weapon, n"NailUnequip", true);

		OnNailUnequipped.Broadcast(Weapon);
		Weapon.OnNailUnequipped.Broadcast(Player);
	}

	void RequestNailRecall(ANailWeaponActor NailToBeRecalled)
	{
		NailRecallQueue.AddUnique(NailToBeRecalled);
		// NailRecallQueue.Add(NailToBeRecalled);
	}

	void RecallNail(ANailWeaponActor NailToBeRecalled)
	{
		if (NailToBeRecalled == nullptr)
		{
			// Why is this happening!?
			ensure(false);
			return;
		}

		FNailRecallData NailRecallData;
		NailRecallData.Player = Player;
		NailRecallData.Nail = NailToBeRecalled;

		if(NailToBeRecalled.Mesh.IsSimulatingPhysics() || !IsPierced(NailToBeRecalled))
			NailRecallData.WiggleTimeRemaining = 0.f;
		else
		{
			ForceFinishPiercingWiggle(NailToBeRecalled);

			NailRecallData.WiggleTimeRemaining = WiggleTime;

			// We'll wiggle the nail less if it was fully submerged
			if (NailToBeRecalled.Mesh.AttachParent != nullptr)
			{
				const UPrimitiveComponent AttachParentPrim = Cast<UPrimitiveComponent>(NailToBeRecalled.Mesh.AttachParent);
				NailRecallData.bWasFullySubmerged = !AttachParentPrim.HasTag(ComponentTags::NailSwingable);
			}

			///////////////////////////
			//// TEMP testing 
			// NailRecallData.InitRecallPhysics();
			// NailRecallData.WiggleTimeRemaining = FMath::Lerp(WiggleTime, 0.f, FMath::Pow(NailRecallData.ETARatio, 0.7f));
			// Print("WiggleTime: " + NailRecallData.WiggleTimeRemaining, Duration = 5.f);
			///////////////////////////

			NailRecallData.WiggleRotator.SnapTo(NailToBeRecalled.GetActorRotation());
			NailRecallData.StartWiggleDirection = NailToBeRecalled.GetActorQuat().GetUpVector();

			NailToBeRecalled.OnNailWiggleStart.Broadcast();
		}

		NailsThrown.Remove(NailRecallData.Nail);
		NailsBeingRecalled.Add(NailRecallData);
	}

	void UpdateNailRecallMovement(const float DeltaTime)
	{
		for (int i = NailsBeingRecalled.Num() - 1; i >= 0; i--)
		{
			if(!NailsBeingRecalled.IsValidIndex(i))
			{
				devEnsure(false, "Nail recall index was invalid. Please notify Sydney");

				// This might happen in network. Not quite sure why yet.
				// I assume it has to do with us doing a bad ForceFinishingNailRecall() somewhere
				break;
			}

			FNailRecallData& NailData = NailsBeingRecalled[i];

			// update wiggle
			if(NailData.WiggleTimeRemaining > 0.f)
			{
				NailData.UpdateWiggle(DeltaTime);
				continue;	// !!!
			}
			else if(!NailData.bFinishedWiggling)
			{
				// init recall
				HandleWiggleFinished(NailData);
			}

			const FVector NewLocationOnRecallSpline = NailData.UpdateLocationOnRecallSpline(DeltaTime);
			
			TArray<AActor> ActorsToIgnore;
			GetActorsToIgnore(ActorsToIgnore);
			NailData.HandleCollisionsAlongRecallPath(NewLocationOnRecallSpline, ActorsToIgnore);

			NailData.ApplyRecallMovement(NewLocationOnRecallSpline, DeltaTime);

			if(NailData.LerpAlpha >= 1.f)
			{
				// !!! It isn't crucial that the nails arrive at the hand at the same time
				// Other capabilities will force recall the nail if needed. 
				ForceFinishNailRecallForNail(NailData.Nail);
			}

		}
	}
	
	void HandleWiggleFinished(FNailRecallData& RecallData) 
	{
		// Make sure that we ignore the actors which we are 
		// overlapping initially upon recalling the nail
		TArray<AActor> OutActors;
		TArray<AActor> ActorsToIgnore;
		GetActorsToIgnore(ActorsToIgnore);
		if(Trace::SphereOverlapActorsMultiByChannel(
			OutActors,
			RecallData.Nail.GetActorLocation(),
			100.f, // Nail length
			ETraceTypeQuery::WeaponTrace,
			ActorsToIgnore
		))
		{
			// System::DrawDebugSphere(NailToBeRecalled.GetActorLocation(), 50.f, 32, FLinearColor::DPink, 5.f);
			RecallData.OverlappedActorsToIgnore = OutActors;
		}

		const FVector NailAngularVelocity = RecallData.Nail.Mesh.GetPhysicsAngularVelocityInDegrees();
		RecallData.StartRecallQuat.SnapTo(
			RecallData.Nail.Mesh.GetComponentQuat(),
			NailAngularVelocity.GetSafeNormal(),
			NailAngularVelocity.Size()
		);

		RecallData.StartRecallLocation.SnapTo(
			RecallData.Nail.Mesh.GetWorldLocation(),
			RecallData.Nail.Mesh.GetPhysicsLinearVelocity()
		);

		if(!RecallData.Nail.Mesh.IsSimulatingPhysics() && IsPierced(RecallData.Nail))
			RecallData.Nail.OnNailWiggleEnd.Broadcast();

		UnpierceActors(RecallData.Nail);

		Player.SetAnimBoolParam(n"RecallingSingle", true);
		RecallData.Nail.StopSweeping();
		RecallData.Nail.Mesh.DisableAndCachePhysicsSettings();

		RecallData.InitRecallPhysics();

		RecallData.Nail.OnNailRecalled.Broadcast(RecallData.EstimatedTravelTime);

		RecallData.bFinishedWiggling = true;

		// NailRecallData.Nail.Mesh.EnableAndApplyCachedPhysicsSettings();
		// NailRecallData.Nail.Mesh.SetSimulatePhysics(false);
	}

	// @TODO: we shouldn't need this. Only case is when you throw 
	// the nail at May... and her hammer but she isnt included her anyway
	void GetActorsToIgnore(TArray<AActor>& OutActorsToIgnore) const
	{
		OutActorsToIgnore.Add(Player);

		if(NailEquippedToHand != nullptr)
		OutActorsToIgnore.Add(NailEquippedToHand);

		for (auto IterNail : NailsEquippedToBack)
			OutActorsToIgnore.Add(IterNail);

		for (auto NailRecallData : NailsBeingRecalled)
			OutActorsToIgnore.Add(NailRecallData.Nail);
	}

	bool IsNailBeingRecalled(ANailWeaponActor InNail) const
	{
		if(NailRecallQueue.Contains(InNail))
			return true;

		for(const FNailRecallData& NailRecallData : NailsBeingRecalled)
		{
			if(NailRecallData.Nail == InNail)
				return true;
		}

		return false;
	}

	bool IsWigglingIntoPierce(ANailWeaponActor InNail) const
	{
		return InNail.PiercingComponent.WiggleIntoPierce.bEnabled;
	}

	bool IsWigglingOutOfPierce(AActor InNail) const
	{
		for(const FNailRecallData& NailRecallDataIter : NailsBeingRecalled)
		{
			if(NailRecallDataIter.Nail == InNail)
				return NailRecallDataIter.WiggleTimeRemaining > 0.f;
		}

		return false;
	}

	bool IsNailEquipped(ANailWeaponActor InNail) const
	{
		return NailEquippedToHand == InNail || NailsEquippedToBack.Contains(InNail);
	}

	bool IsNailRecallable(ANailWeaponActor InNail) const 
	{
		return InNail.bSweep || NailsThrown.Num() < 2;
	}

	UFUNCTION(BlueprintPure)
	int GetNumNailsEquipped() const
	{
		return (NailsEquippedToBack.Num() + (NailEquippedToHand != nullptr ? 1 : 0));
	}

	UFUNCTION(BlueprintPure)
	bool HasNailsEquipped() const 
	{
		if (NailsEquippedToBack.Num() > 0)
			return true;

		if (NailEquippedToHand != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	int GetNumNailsOwnedByWielder() const
	{
		return (NailsThrown.Num() + GetNumNailsEquipped() + NailsBeingRecalled.Num());
	}

	UFUNCTION(BlueprintPure)
	bool IsOwnerOfNails() const
	{
		return GetNumNailsOwnedByWielder() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool HasThrownNails() const 
	{
		return NailsThrown.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool HasNailEquippedToHand() const 
	{
		return NailEquippedToHand != nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool MultipleNailsHaveBeenThrown() const
	{
		return NailsThrown.Num() > 1;
	}

	ANailWeaponActor GetClosestRecallableNailToLineDirection(
		const FVector& LineOrigin,
		const FVector& LineDirectionNormal
	) const
	{
		TArray<ANailWeaponActor> NailsToQuery = NailsThrown;

		// flying nails are top priority.
		if(AreAnyNailsBeingThrownOrSimulating(NailsToQuery))
			NailsToQuery = GetNonPiercedNails(NailsThrown);

		return FindClosestNailInDirection(NailsToQuery, LineOrigin, LineDirectionNormal);
	}

	ANailWeaponActor FindClosestNailInDirection( 
		const TArray<ANailWeaponActor>& InNails,
		const FVector& LineOrigin,
		const FVector& LineDirectionNormal
	) const
	{
		ANailWeaponActor ClosestNail = nullptr;
		float ClosestDistance_SQ = BIG_NUMBER;

		for (int i = InNails.Num() - 1; i >= 0; --i)
		{
			const FVector NailLocation = InNails[i].GetActorLocation();
			const float DistanceAlongLine = (NailLocation - LineOrigin).DotProduct(LineDirectionNormal);

			// don't care about nails behind the line direction normal
			if (DistanceAlongLine < 0.f)
				continue;

			// Only recall nails that are on screen
			if(SceneView::IsInView(Player, NailLocation) == false)
				continue;

			const FVector NailLocationProjectedOnLine = LineOrigin + (LineDirectionNormal * DistanceAlongLine);
			const float NailToLineDistance_SQ = (NailLocationProjectedOnLine - NailLocation).SizeSquared();
			if (NailToLineDistance_SQ < ClosestDistance_SQ)
			{
				ClosestDistance_SQ = NailToLineDistance_SQ;
				ClosestNail = InNails[i];
			}
		}

		return ClosestNail;
	}

	TArray<ANailWeaponActor> GetNonPiercedNails(const TArray<ANailWeaponActor>& InNails) const
	{
		TArray<ANailWeaponActor> FilteredNails = InNails;
		for (int i = FilteredNails.Num() - 1; i >= 0; --i)
		{
			if(IsPierced(FilteredNails[i]))
			{
				FilteredNails.RemoveAtSwap(i);
			}
		}
		return FilteredNails;
	}

	TArray<ANailWeaponActor> GetSweepingNails(const TArray<ANailWeaponActor>& InNails) const
	{
		TArray<ANailWeaponActor> FilteredNails = InNails;
		for (int i = FilteredNails.Num() - 1; i >= 0; --i)
		{
			if(!FilteredNails[i].bSweep)
			{
				FilteredNails.RemoveAtSwap(i);
			}
		}
		return FilteredNails;
	}

	TArray<ANailWeaponActor> GetSimulatedNails(const TArray<ANailWeaponActor>& InNails) const
	{
		TArray<ANailWeaponActor> FilteredNails = InNails;
		for (int i = FilteredNails.Num() - 1; i >= 0; --i)
		{
			if(!FilteredNails[i].Mesh.IsSimulatingPhysics())
			{
				FilteredNails.RemoveAtSwap(i);
			}
		}
		return FilteredNails;
	}

	bool AreAnyNailsSweeping(const TArray<ANailWeaponActor>& InNails) const
	{
		for (int i = InNails.Num() - 1; i >= 0; --i)
		{
			if(InNails[i].bSweep)
			{
				return true;
			}
		}
		return false;
	}

	bool AreAnyNailsBeingThrownOrSimulating(const TArray<ANailWeaponActor>& InNails) const
	{
		for (int i = InNails.Num() - 1; i >= 0; --i)
		{
			if (InNails[i].bSweep || InNails[i].Mesh.IsSimulatingPhysics())
			{
				return true;
			}
		}
		return false;
	}

	bool AreAnyNailsSimulating(const TArray<ANailWeaponActor>& InNails) const
	{
		for (int i = InNails.Num() - 1; i >= 0; --i)
		{
			if (InNails[i].Mesh.IsSimulatingPhysics())
			{
				return true;
			}
		}
		return false;
	}

	bool AreAnyNailsPierced(const TArray<ANailWeaponActor>& InNails) const
	{
		for (int i = InNails.Num() - 1; i >= 0; --i)
		{
			if (IsPierced(InNails[i]))
			{
				return true;
			}
		}
		return false;
	}

	/* Only checks nails in that direction. Anything behind that vector will be ignored. */
	UFUNCTION(BlueprintPure)
	ANailWeaponActor GetClosestNailThrownToLineDirection(FVector LineOrigin, FVector LineDirectionNormal) const
	{
		ANailWeaponActor ClosestNail = nullptr;
		float ClosestDistance_SQ = BIG_NUMBER;
		for (int i = NailsThrown.Num() - 1; i >= 0; --i)
		{
			const FVector NailLocation = NailsThrown[i].GetActorLocation();
			const float DistanceAlongLine = (NailLocation - LineOrigin).DotProduct(LineDirectionNormal);

			// don't care about nails behind the line direction normal
			if (DistanceAlongLine < 0.f)
				continue;

			const FVector NailLocationProjectedOnLine = LineOrigin + (LineDirectionNormal * DistanceAlongLine);
			const float NailToLineDistance_SQ = (NailLocationProjectedOnLine - NailLocation).SizeSquared();
			if (NailToLineDistance_SQ < ClosestDistance_SQ)
			{
				ClosestDistance_SQ = NailToLineDistance_SQ;
				ClosestNail = NailsThrown[i];
			}
		}
		return ClosestNail;
	}

	ANailWeaponActor GetClosestNailThrownWithinConeAngle(FVector ConeOrigin, FVector NormalizedConeDirection, float ConeCosAngle) const
	{
		ANailWeaponActor ClosestNail = nullptr;
		float ClosestDistance_SQ = BIG_NUMBER;
		for (int i = NailsThrown.Num() - 1; i >= 0; --i)
		{
			const FVector NailLocation = NailsThrown[i].GetActorLocation();
			const FVector ToNail = NailLocation - ConeOrigin;
			const FVector ToNailNormalized = ToNail.GetSafeNormal();
			const float ToNailCosAngle = NormalizedConeDirection.DotProduct(ToNailNormalized);
			// Will only return true for the nails that are located 
			// in the same direction as the cone direction.
			if (ToNailCosAngle > ConeCosAngle)
			{
				const float DistanceToNail_SQ = ToNail.SizeSquared();
				if (DistanceToNail_SQ < ClosestDistance_SQ) 
				{
					ClosestDistance_SQ = DistanceToNail_SQ;
					ClosestNail = NailsThrown[i];
				}
			}
		}
		return ClosestNail;
	}
}

struct FNailRecallData 
{

	bool opEquals(const FNailRecallData& Other) const
	{
		return Nail == Other.Nail;
	}

	bool opEquals(FNailRecallData& Other) const
	{
		return Nail == Other.Nail;
	}

	UPROPERTY()
	bool bWasFullySubmerged = false;

	UPROPERTY()
	FVector StartLocation = FVector::ZeroVector;

	UPROPERTY()
	FHazeAcceleratedVector StartRecallLocation;

	UPROPERTY()
	FQuat StartQuat = FQuat::Identity;

	// rotation + velocity at start of recall
	UPROPERTY()
	FHazeAcceleratedQuat StartRecallQuat;

	UPROPERTY()
	FQuat EndQuat = FQuat::Identity;

	UPROPERTY()
	FVector MidOffset = FVector::ZeroVector;

	UPROPERTY()
	ANailWeaponActor Nail = nullptr;

	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY()
	FHazeAcceleratedVector AccMidLocation;

	UPROPERTY()
	FHazeAcceleratedVector AccEndLocation;

	UPROPERTY()
	float LerpAlpha = 0.f;

	UPROPERTY()
	float LinearDistanceCrossed = 0.f;

	UPROPERTY()
	float DistanceToFly = 0.f;

	UPROPERTY()
	float RecallSpeed = 0.f;

	UPROPERTY()
	float RecallAcceleration = 0.f;

	// Quick and dirty scaler used for prototyping. 
	UPROPERTY()
	float ETARatio = 1.f;

	UPROPERTY()
	float TimeUntilArrival = 0.f;

	UPROPERTY()
	float EstimatedTravelTime = 0.f;

	UPROPERTY()
	FHitResult CollisionData;

	UPROPERTY()
	TArray<AActor> OverlappedActorsToIgnore;

	UPROPERTY()
	bool bFinishedWiggling = false;

	UPROPERTY()
	float WiggleTimeRemaining = 0.f;

	UPROPERTY()
	FVector StartWiggleDirection = FVector::ZeroVector;

	UPROPERTY()
	FHazeAcceleratedRotator WiggleRotator;

	float SubStepTimeToProcess = 0.f;
	const float FixedDeltaTime = 1.f / 120.f;

	void ApplyRecallMovement(const FVector& DesiredLocation, const float DeltaTime)
	{
		Nail.MovementComponent.Velocity = DesiredLocation - Nail.GetActorLocation();
		Nail.MovementComponent.Velocity /= DeltaTime;

		Nail.SetActorLocation(DesiredLocation);

		// fixed step it in order to ensure frame rate independent animations
		SubStepTimeToProcess += DeltaTime;
		while(SubStepTimeToProcess >= FixedDeltaTime)
		{
			StartRecallQuat.SpringTo(EndQuat, 15.f, 0.4f, FixedDeltaTime);
			// StartRecallQuat.SpringTo(EndQuat, 3.5f, 0.4f, DeltaTime);
			StartRecallLocation.SpringTo(StartRecallLocation.Value, 10.f, 0.4f, FixedDeltaTime);
			SubStepTimeToProcess -= FixedDeltaTime;
		}

		StartLocation = StartRecallLocation.Value;

		Nail.SetActorRotation(StartRecallQuat.Value);

		// const float QuatAlpha = FMath::Pow(LerpAlpha, 2.f);
		// const FQuat SlerpedQuat = FQuat::Slerp(StartQuat, EndQuat, QuatAlpha); 
		// Nail.SetActorRotation(SlerpedQuat);

		// Scaling back the nail because 
		// Per wanted to try out scaling the nail once attached.
		FVector LerpedScale = FMath::Lerp(
			Nail.GetActorScale3D(),
			FVector(1.f),
			LerpAlpha
		);
		Nail.SetActorScale3D(LerpedScale);

//		float QuatError = FQuat::ErrorAutoNormalize(Nail.GetActorQuat(), EndQuat);
//		PrintToScreenScaled("QuatError: " + QuatError, 1.f, FLinearColor::Yellow, 1.f);

		// PrintToScreenScaled("Recall start location: " + StartRecallLocation.Value, 1.f, FLinearColor::Yellow, 1.f);
		// PrintToScreenScaled("Recall start speed: " + StartRecallLocation.Velocity.Size(), 1.f, FLinearColor::Yellow, 1.f);

		// const FName HandSocket = GetNailSocketNameFromDefinition(ENailSocketDefinition::NailWeapon_HandCatch);
		// System::DrawDebugPoint(Player.Mesh.GetSocketLocation(HandSocket), 3.f, FLinearColor::Green, 0.f);

		// System::DrawDebugPoint(StartLocation, 3.f, FLinearColor::Yellow, 0.f);

		// for (FVector P : CRPoints)
		// {
		// 	if (P != NailData.Nail.GetActorLocation())
		// 	{
		// 		System::DrawDebugPoint(P, 5.f, PointColor = FLinearColor::Yellow, Duration = 0.f);
		// 	}
		// }

	}

	void HandleCollisionsAlongRecallPath(const FVector& DesiredNewLocation, const TArray<AActor>& InActorsToIgnore)
	{
		TArray<AActor> ActorsToIgnore = InActorsToIgnore;
		if(OverlappedActorsToIgnore.Num() != 0)
			ActorsToIgnore.Append(OverlappedActorsToIgnore);

		FHitResult HitData;
		const bool bHit = RayTrace(DesiredNewLocation, ActorsToIgnore, HitData);
		if(bHit && !CollisionData.bBlockingHit)
		{
			CollisionData = HitData;
			Nail.OnNailRecallEnterCollision.Broadcast(TimeUntilArrival, HitData);
		}
		else if(!bHit && CollisionData.bBlockingHit)
		{
			FHitResult ExitHitData;
			if(RayTrace(CollisionData.ImpactPoint, ActorsToIgnore, ExitHitData))
			{
				Nail.OnNailRecallExitCollision.Broadcast(TimeUntilArrival, ExitHitData);
				CollisionData.Reset();
			}
		}
		else if(!bHit && OverlappedActorsToIgnore.Num() != 0 && CalcInAirTime() > 0.1f)
		{
			// we are free the inital collision, forget about those actors 
			OverlappedActorsToIgnore.Reset();
		}
	}

	// @TODO: we shoulndt have separate traces. Difficult to manage!
	bool RayTrace(FVector End, const TArray<AActor>& ActorsToIgnore, FHitResult& OutTraceData)
	{
		/* Will only return first blocking hit. No overlaps. */
		return System::LineTraceSingle
		(
			Nail.GetActorLocation(),
			End,
			ETraceTypeQuery::WeaponTrace,
			false,
			ActorsToIgnore,
			EDrawDebugTrace::None,
			OutTraceData,
			true
		);
	}

	FVector UpdateLocationOnRecallSpline(const float DeltaTime)
	{
		UpdateRecallPhysics(DeltaTime);

		TArray<FVector> SplinePoints;
		FVector EnterTangentPoint, ExitTangentPoint = FVector::ZeroVector;
		GetUpdatedRecallSplinePoints(EnterTangentPoint, SplinePoints, ExitTangentPoint, DeltaTime);

		// const FVector Location = Math::GetLocationOnCRSpline(
		const FVector Location = Math::GetLocationOnCRSplineConstSpeed(
			EnterTangentPoint,
			SplinePoints,
			ExitTangentPoint,
			LerpAlpha,
			0.5f
		);

		return Location;
	}

	void InitRecallSplinePoints()
	{
		const FName SocketName = GetNailSocketNameFromDefinition(ENailSocketDefinition::NailWeapon_HandCatch);
		const FVector PlayerLocation = Player.GetActorLocation();
		const FQuat PlayerRot = Player.GetActorQuat();
		const FVector PlayerHandLocation = Player.Mesh.GetSocketLocation(SocketName); 

		AccEndLocation.SnapTo( PlayerHandLocation, FVector::ZeroVector);

		FVector Halfway = StartLocation;
		Halfway += (PlayerLocation - StartLocation) * 0.3f;
		MidOffset = FVector(0.f, -800.f, 250.f);
		const FVector HalfwayOffsetRotated = PlayerRot.RotateVector(MidOffset) * ETARatio;
		Halfway += HalfwayOffsetRotated;

		// this will make it go linearly in the beginning. 
		// proper fix if to add more points in the beginning?
		AccMidLocation.SnapTo(PlayerHandLocation, FVector::ZeroVector);
		// AccMidLocation.SnapTo(Halfway, FVector::ZeroVector);
	}

	void GetDesiredRecallSplinePoints(
		FVector& EnterTangentPoint,
		TArray<FVector>& Points,
		FVector& ExitTangentPoint
	) 
	{
		const FQuat PlayerRot = Player.GetActorQuat();
		const FVector PlayerLocation = Player.GetActorLocation();
		const FName SocketName = GetNailSocketNameFromDefinition(ENailSocketDefinition::NailWeapon_HandCatch);

		const FVector DesiredEndSplineLocation = Player.Mesh.GetSocketLocation(SocketName);

		FVector DesiredHalfway = StartLocation;
		DesiredHalfway += (PlayerLocation - StartLocation) * 0.3f;
		FVector HalfwayOffset = MidOffset;
		FVector HalfwayOffsetRotated = PlayerRot.RotateVector(HalfwayOffset);
		HalfwayOffsetRotated *= ETARatio;
		DesiredHalfway += HalfwayOffsetRotated;

		////////////////////////////////////////////////////7
		EnterTangentPoint = PlayerLocation;
		Points.Add(StartLocation);
		Points.Add(DesiredHalfway);
		Points.Add(DesiredEndSplineLocation);
		ExitTangentPoint = StartLocation;
		////////////////////////////////////////////////////7
	}

	void GetUpdatedRecallSplinePoints(
		FVector& EnterTangentPoint,
		TArray<FVector>& Points,
		FVector& ExitTangentPoint,
		const float DeltaTime
	) 
	{
		// !!!!!!!!!!!!!!!!!!!
		// Update GetDesiredRecallSplinePoints() if you add more points
		// !!!!!!!!!!!!!!!!!!!

		const FQuat PlayerRot = Player.GetActorQuat();
		const FVector PlayerLocation = Player.GetActorLocation();
		const FName SocketName = GetNailSocketNameFromDefinition(ENailSocketDefinition::NailWeapon_HandCatch);

		const FVector DesiredEndSplineLocation = Player.Mesh.GetSocketLocation(SocketName);
		const FVector EndSplineLocation = AccEndLocation.AccelerateTo(
			DesiredEndSplineLocation,
			FMath::Sqrt(TimeUntilArrival),
			DeltaTime
		);

		FVector DesiredHalfway = StartLocation;
		DesiredHalfway += (PlayerLocation - StartLocation) * 0.3f;
		FVector HalfwayOffset = MidOffset;
		FVector HalfwayOffsetRotated = PlayerRot.RotateVector(HalfwayOffset);
		HalfwayOffsetRotated *= ETARatio;
		DesiredHalfway += HalfwayOffsetRotated;
		const FVector Halfway = AccMidLocation.AccelerateTo(
			DesiredHalfway,
			FMath::Sqrt(TimeUntilArrival),
			DeltaTime
		);

		////////////////////////////////////////////////////
		EnterTangentPoint = PlayerLocation;
		Points.Add(StartLocation);
		Points.Add(Halfway);
		Points.Add(EndSplineLocation);
		ExitTangentPoint = StartLocation;
		////////////////////////////////////////////////////
	}

	void InitRecallPhysics()
	{
		const FName SocketName = GetNailSocketNameFromDefinition(ENailSocketDefinition::NailWeapon_HandCatch);
		EndQuat = Player.Mesh.GetSocketQuaternion(SocketName);
		// EndQuat *= FQuat(EndQuat.GetUpVector(), PI/2.f);
		StartLocation = Nail.GetActorLocation();
		StartRecallLocation.Value = StartLocation;
		StartQuat = Nail.Mesh.GetComponentQuat();
		StartRecallQuat.Value = StartQuat;

		////////////////
		// Settings
		RecallSpeed = 5000.f;
		RecallAcceleration = 500.f; // 3500?
		float MaxFlightTime = 1.5f;
		MaxFlightTime -= UNailWielderComponent::GetOrCreate(Player).WiggleTime;
		if(MaxFlightTime <= 0.f)
			MaxFlightTime = KINDA_SMALL_NUMBER;
		////////////////

		/*
			Our spline point positions are based on what physics parameters we use.
			1. Calculate physics parameters based on linear estimates
			2. calculate spline points based on those linear estimates
			3. recalculate the physics params with spline curve in mind
			4. refine the spline points based on the new physics params
		*/

		// update params based on a linear path guesstimate
		{
			const FVector PlayerHandLocation = Player.Mesh.GetSocketLocation(SocketName); 
			const FVector ToEnd = PlayerHandLocation - Nail.GetActorLocation();
			DistanceToFly = ToEnd.Size();

			// Predict time of arrival base on a linear path
			EstimatedTravelTime = PredictTimeOfArrival();
			ETARatio = FMath::Clamp(EstimatedTravelTime / MaxFlightTime, 0.f, 1.f);
			TimeUntilArrival = EstimatedTravelTime;

			// init points based on a linear path
			InitRecallSplinePoints();

//			PrintToScreen("DistanceToFly: " + DistanceToFly, 10.f, FLinearColor::Yellow);
//			PrintToScreen("EstimatedTravelTime: " + EstimatedTravelTime, 10.f, FLinearColor::Yellow);

			// const float DebugTime = 3.f;
			// const FLinearColor RandomColor = FLinearColor::Yellow;
			// System::DrawDebugPoint(StartLocation, 10.f, RandomColor, DebugTime);
			// System::DrawDebugPoint(AccMidLocation.Value, 10.f, RandomColor, DebugTime);
			// System::DrawDebugPoint(AccEndLocation.Value, 10.f, RandomColor, DebugTime);
		}

		// Update params based on a spline path
		{
			TArray<FVector> SplinePoints;
			FVector EnterTangentPoint, ExitTangentPoint = FVector::ZeroVector;
			GetDesiredRecallSplinePoints(EnterTangentPoint, SplinePoints, ExitTangentPoint);
			DistanceToFly = Math::GetCRSplineLengthConstSpeed(EnterTangentPoint, SplinePoints, ExitTangentPoint);

			ReachTargetByAddingExtraMomentum(MaxFlightTime);

			// Predict time of arrival based on the spline path
			EstimatedTravelTime = PredictTimeOfArrival();
			ETARatio = FMath::Clamp(EstimatedTravelTime / MaxFlightTime, 0.f, 1.f);
			TimeUntilArrival = EstimatedTravelTime;

			// re-init the points based on the new path
			InitRecallSplinePoints();

			// const float DebugTime = 3.f;
			// const FLinearColor RandomColor = FLinearColor::Red;
			// PrintToScreenScaled("DistanceToFly (Spline): " + DistanceToFly, DebugTime, RandomColor);
			// System::DrawDebugPoint(StartLocation, 10.f, RandomColor, DebugTime);
			// System::DrawDebugPoint(AccMidLocation.Value, 10.f, RandomColor, DebugTime);
			// System::DrawDebugPoint(AccEndLocation.Value, 10.f, RandomColor, DebugTime);
		}

	}

	float CalcInAirTime() const
	{
		return FMath::Min(0.f, EstimatedTravelTime - TimeUntilArrival);
	}

	void UpdateWiggle(const float Dt)
	{
		WiggleTimeRemaining = FMath::Max(WiggleTimeRemaining - Dt, 0.f);

		const float Damping = 0.6f;
		const float Stiffness = 150.f;

		float ConeAngleThreshold = PI * 0.5f;

		if(bWasFullySubmerged)
			ConeAngleThreshold = PI * 0.37f;

		if(Game::GetMay().IsAnyCapabilityActive(n"SwingBar"))
			ConeAngleThreshold = PI * 0.25f;

		const FVector RandomConeDirection = FMath::VRandCone(StartWiggleDirection, ConeAngleThreshold); 
		WiggleRotator.SpringTo(
			FRotator::MakeFromZ(RandomConeDirection),
			Stiffness,
			Damping,
			Dt	
		);

		const FVector ToPlayer = (Player.GetActorLocation() - Nail.GetActorLocation());
		const FVector ToPlayerConstrained = Math::ConstrainVectorToCone(
			ToPlayer,
			StartWiggleDirection,
			ConeAngleThreshold
		);

		WiggleRotator.AccelerateTo(
			Math::MakeRotFromZ(ToPlayerConstrained),
			// Math::MakeRotFromZ(ToPlayer),
			// WielderComp.WiggleTime,
			2.5f * WiggleTimeRemaining,
			Dt	
		);

		Nail.SetActorRotation(WiggleRotator.Value);
		StartQuat = FQuat(WiggleRotator.Value);

	}

	void UpdateRecallPhysics(const float Dt)
	{
		LinearDistanceCrossed += (RecallSpeed * Dt);
		LinearDistanceCrossed += (RecallAcceleration * Dt * Dt * 0.5f);
		RecallSpeed += (RecallAcceleration * Dt);
		LerpAlpha = FMath::Clamp(LinearDistanceCrossed / DistanceToFly, 0.f, 1.f);

		TimeUntilArrival -= Dt;
		if (TimeUntilArrival <= 0.f)
		{
			TimeUntilArrival = 0.f;
//			PrintToScreen("Final RecallSpeed: " + RecallSpeed, 10.f, FLinearColor::Yellow);
//			PrintToScreen("----", 10.f, FLinearColor::Yellow);
//			PrintToScreen("\n\n", 10.f, FLinearColor::Yellow);
		}
	}

	void ReachTargetByAddingExtraMomentum(const float MaxFlightTime = 1.5f)
	{
		// modify speed/acceleration to ensure that 
		// we reach the target on the desired time. 
		if (MaxFlightTime > 0.f)
		{
			const float DistMovedFromSpeed = RecallSpeed * MaxFlightTime;
			const float DistMovedFromAcceleration = 0.5f * MaxFlightTime * MaxFlightTime * RecallAcceleration;
			const float DistMovedOverMaxLerpTime = DistMovedFromSpeed + DistMovedFromAcceleration;
			if (DistMovedOverMaxLerpTime < DistanceToFly)
			{
				const float DeltaDistanceNeeded = DistanceToFly - DistMovedOverMaxLerpTime;

				const float ExtraAcceleration = (DeltaDistanceNeeded / (MaxFlightTime * MaxFlightTime * 0.5f));
				RecallAcceleration += ExtraAcceleration;
//				Print("More Acceleration Needed: " + ExtraAcceleration, Duration = 5.f);

// 				const float ExtraSpeed = (DeltaDistanceNeeded / MaxFlightTime);
//				RecallSpeed += ExtraSpeed;
// 				Print("More Speed Needed: " + ExtraSpeed, Duration = 5.f);
			}
		}
	}

	float PredictTimeOfArrival() const
	{
		float ETA = 0.f;
		const float A = DistanceToFly;
		const float B = RecallSpeed;
		const float C = RecallAcceleration * 0.5f;
		if (C == 0.f && B != 0.f)
		{
			ETA = A / B;
		}
		else if (C != 0.f)
		{
 			const float TheSqrt = FMath::Sqrt((4.f*A*C) + (B*B));
			const float R1 = (TheSqrt - B) / (2.f*C);
			const float R2 = (-(TheSqrt + B)) / (2.f*C);
			ETA = R1 > 0.f ? R1 : R2;
		}
		else 
		{
			ETA = 0.f;
		}
		return ETA;
	}

};
