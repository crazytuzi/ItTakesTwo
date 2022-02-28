
import Vino.Pierceables.PierceStatics;
import Cake.Weapons.Nail.NailWeaponStatics;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailSocketDefinition;

UCLASS(abstract)
class UNailEventHandler : UHazeCapability
{
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"NailEvents");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	UPROPERTY()
	ANailWeaponActor Nail = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Nail = Cast<ANailWeaponActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Nail.OnNailThrownEvent.AddUFunction(this, n"HandleNailThrown");
		Nail.OnNailCollision.AddUFunction(this, n"HandleNailCollision");

		Nail.OnNailEquipped.AddUFunction(this, n"HandleNailEquipped");
		Nail.OnNailUnequipped.AddUFunction(this, n"HandleNailUnequipped");

		Nail.PiercingComponent.Unpierced.AddUFunction(this, n"HandleNailUnpierced");
		Nail.PiercingComponent.Pierced.AddUFunction(this, n"HandleNailPierced");

		Nail.OnDestroyed.AddUFunction(this, n"HandleNailDestroyed");

		Nail.OnNailWiggleStart.AddUFunction(this, n"HandleWiggleStarted");
		Nail.OnNailWiggleEnd.AddUFunction(this, n"HandleWiggleEnded");
		Nail.OnNailRecalled.AddUFunction(this, n"HandleNailRecalled");

		Nail.OnNailPreCaughtEvent.AddUFunction(this, n"HandleNailPreCaught");
		Nail.OnNailPostCaughtEvent.AddUFunction(this, n"HandleNailPostCaught");

		Nail.OnNailRecallEnterCollision.AddUFunction(this, n"HandleNailRecallCollisionEnter");
		Nail.OnNailRecallExitCollision.AddUFunction(this, n"HandleNailRecallCollisionExit");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Nail.OnNailThrownEvent.Unbind(this, n"HandleNailThrown");
		Nail.OnNailCollision.Unbind(this, n"HandleNailCollision");

		Nail.OnNailEquipped.Unbind(this, n"HandleNailEquipped");
		Nail.OnNailUnequipped.Unbind(this, n"HandleNailUnequipped");

		Nail.PiercingComponent.Unpierced.Unbind(this, n"HandleNailUnpierced");
		Nail.PiercingComponent.Pierced.Unbind(this, n"HandleNailPierced");

		Nail.OnDestroyed.Unbind(this, n"HandleNailDestroyed");

		Nail.OnNailWiggleStart.Unbind(this, n"HandleWiggleStarted");
		Nail.OnNailWiggleEnd.Unbind(this, n"HandleWiggleEnded");
		Nail.OnNailRecalled.Unbind(this, n"HandleNailRecalled");

		Nail.OnNailPreCaughtEvent.Unbind(this, n"HandleNailPreCaught");
		Nail.OnNailPostCaughtEvent.Unbind(this, n"HandleNailPostCaught");

		Nail.OnNailRecallEnterCollision.Unbind(this, n"HandleNailRecallCollisionEnter");
		Nail.OnNailRecallExitCollision.Unbind(this, n"HandleNailRecallCollisionExit");
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleWiggleStarted() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleWiggleEnded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailRecallCollisionEnter(const float TravelTimeRemaining, FHitResult HitData) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailRecallCollisionExit(const float TravelTimeRemaining, FHitResult HitData) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailPreCaught() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailPostCaught() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailThrown() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailRecalled(const float EstimatedTravelTime) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailUnpierced() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailCollision(const FHitResult& HitData) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailEquipped(AHazePlayerCharacter Wielder) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailUnequipped(AHazePlayerCharacter Wielder) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailDestroyed(AActor DestroyedActor) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void HandleNailPierced(
		AActor ActorDoingThePiercing,
		AActor ActorBeingPierced,
		UPrimitiveComponent ComponentBeingPierced,
		const FHitResult& HitResult
	) {}

}
