import Peanuts.WeaponTrace.WeaponBlockingComponent;

namespace WeaponTrace
{
	bool IsAutoAimBlockingComponent(UPrimitiveComponent HitComponent)
	{
		if (HitComponent == nullptr)
			return false; 

		return HitComponent.HasTag(ComponentTags::BlockAutoAim);
	}

	bool IsProjectileBlockingComponent(UPrimitiveComponent HitComponent)
	{
		if (HitComponent == nullptr)
			return false; 

		return HitComponent.HasTag(ComponentTags::BlockAutoAim);
	}

	bool HasProjectileBlockingComponent(AActor Actor)
	{
		if (Actor == nullptr)
			return false; 

		TArray<UActorComponent> BlockingComps;
		Actor.GetComponentsByClass(UWeaponBlockingComponent::StaticClass(), BlockingComps);
		for (UActorComponent Comp : BlockingComps)
		{
			UPrimitiveComponent Prim = Cast<UPrimitiveComponent>(Comp);
			if ((Prim != nullptr) && Prim.HasTag(ComponentTags::BlockAutoAim))
				return true;
		}
		return false;
	}
}
