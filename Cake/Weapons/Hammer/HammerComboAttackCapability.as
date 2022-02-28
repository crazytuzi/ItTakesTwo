import Vino.ComboAnimations.ComboAnimationCapability;
import Cake.Weapons.Hammer.HammerableStatics;
import Cake.Weapons.Hammer.HammerWielderComponent;

class UHammerComboAttackCapability : UComboAnimationCapability
{
	default CapabilityTags.Add(n"GameplayAction");
	default CapabilityTags.Add(n"HammerWeapon");
	default CapabilityTags.Add(n"HammerSmash");

	UPROPERTY()
	float HammerAttackImpactRadius = 400.f;

	bool ShouldStartCombo() const override
	{
		return WasActionStarted(ActionNames::WeaponFire);
	}

	bool ShouldProceedInCombo() const override
	{
		return WasActionStarted(ActionNames::WeaponFire);
	}

	void ComboHit(int ComboIndex) override
	{
		if (HasControl())
		{
			TArray<UPrimitiveComponent> Components;
			TArray<AActor> ActorsToIgnore;

			auto WielderComp = UHammerWielderComponent::Get(Owner);
			auto Hammer = WielderComp.GetHammer();

			FVector Origin = Hammer.GetActorLocation();

			GetHammerablePrimitivesFromSphereTrace(
				Components,
				ActorsToIgnore,
				Origin,
				HammerAttackImpactRadius, 
				ETraceTypeQuery::WeaponTrace
			);

			if (Components.Num() != 0)
				NetHammerComponents(Components);
		}
	}

	UFUNCTION(NetFunction)
	void NetHammerComponents(TArray<UPrimitiveComponent> Components)
	{
		NotifyHammerableComponentsOfHit(Owner, Components);
	}
}