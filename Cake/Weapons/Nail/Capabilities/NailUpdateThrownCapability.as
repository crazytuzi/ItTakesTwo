

import Vino.Pierceables.PierceStatics;
import Cake.Weapons.Nail.NailWeaponStatics;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWielderComponent;
import Vino.Characters.PlayerCharacter;

/**
 *
 * We need to update all the nails here because of network. 
 * Everything needs to happen on Codys actor-channel.
 *
 */

UCLASS()
class UNailUpdateThrownCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailCollider");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 150;

	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WielderComp.IsOwnerOfNails())
			return EHazeNetworkActivation::DontActivate;

 		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WielderComp.IsOwnerOfNails())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (int i = WielderComp.NailsThrown.Num() - 1; i >= 0; --i)
		{
			ANailWeaponActor& Nail = WielderComp.NailsThrown[i];

			if (Nail.bSweep)
				UpdateMovementAndHandleCollisions(Nail, DeltaTime);
			else if(Nail.Mesh.IsSimulatingPhysics())
				ReactToRagdollCollisions(Nail, DeltaTime);
		}
	}

	void UpdateMovementAndHandleCollisions(ANailWeaponActor InNail, const float Dt)
	{
		TArray<FHitResult> Hits;
		const bool bHit = InNail.MovementComponent.UpdateSweepingMovement(Dt, Hits);

		if (!bHit)
			return;

		if (!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"CollidingNail", InNail);

		// Handle Piercing Collision
		FHitResult PiercingHitData;
		if(InNail.PiercingComponent.GetPiercingHitFromHits(Hits, PiercingHitData))
		{
			NetSendCrumbCollisionHits(InNail, FNailHitData(PiercingHitData));
			CrumbComp.LeaveAndTriggerDelegateCrumb(
				FHazeCrumbDelegate(this, n"CrumbHandlePiercingHit"),
				CrumbParams
			);
		}
		else
		{
			// Handle Collisions
			for (int i = Hits.Num() - 1; i >= 0 ; i--)
			{
				// BSPs might be nullptr..
				if (Hits[i].bBlockingHit && Hits[i].Actor != nullptr)
				{
					const bool bNetworked = Network::IsObjectNetworked(Hits[i].GetActor());
					if(!devEnsure(
						bNetworked,
						"Nail hit " + 
						Hits[i].Actor + 
						", which isn't networked. This might cause problems...\n 
						Let sydney know about this please"))
					{
						continue;
					}

					NetSendCrumbCollisionHits(InNail, FNailHitData(Hits[i]));
					CrumbComp.LeaveAndTriggerDelegateCrumb(
						FHazeCrumbDelegate(this, n"CrumbHandleNonPiercingHit"),
						CrumbParams
					);

					// We only handle the first hit
					break;
				}
			}
		}

	}

	void ReactToRagdollCollisions(ANailWeaponActor InNail, const float Dt)
	{
//		if (!HasControl())
//			return;

		FHitResult RagdollHit;
		if (InNail.SweepForNailCollisionsWhileRagdolling(Dt, RagdollHit))
		{
			// We no longer network this event because it triggered to often. 
			InNail.OnNailCollision.Broadcast(RagdollHit);

//			NetSendCrumbCollisionHits(InNail, RagdollHit); 
//			FHazeDelegateCrumbParams CrumbParams;
//			CrumbParams.AddObject(n"CollidingNail", InNail);
//			CrumbComp.LeaveAndTriggerDelegateCrumb(
//				FHazeCrumbDelegate(this, n"CrumbReactToRagdollCollision"),
//				CrumbParams
//			);
		}
	}

	UFUNCTION()
	void CrumbReactToRagdollCollision(const FHazeDelegateCrumbData& CrumbData)
	{
		ANailWeaponActor CollidingNail = Cast<ANailWeaponActor>(CrumbData.GetObject(n"CollidingNail"));
		CollidingNail.ReactToRagdollCollision();
	}

	UFUNCTION()
	void CrumbHandlePiercingHit(const FHazeDelegateCrumbData& CrumbData)
	{
		ANailWeaponActor CollidingNail = Cast<ANailWeaponActor>(CrumbData.GetObject(n"CollidingNail"));
		CollidingNail.HandlePiercingHit();
	}

	UFUNCTION()
	void CrumbHandleNonPiercingHit(const FHazeDelegateCrumbData& CrumbData)
	{
		ANailWeaponActor CollidingNail = Cast<ANailWeaponActor>(CrumbData.GetObject(n"CollidingNail"));
		CollidingNail.HandleNonPiercingHit();
	}

	UFUNCTION(NetFunction)
	void NetSendCrumbCollisionHits(ANailWeaponActor InNail, FNailHitData InData)
	{
		InNail.QueuedCrumbCollisionHits.Add(InData);
	}

}



















