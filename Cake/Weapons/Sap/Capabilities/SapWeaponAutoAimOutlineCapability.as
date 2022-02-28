import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;
import Peanuts.Outlines.Outlines;

class USapWeaponAutoAimOutlineCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;

	AActor LastActor = nullptr;
	TArray<UPrimitiveComponent> OutlineMeshes;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!Wielder.AimTarget.bIsAutoAim)
	        return EHazeNetworkActivation::DontActivate;

	    if (Wielder.AimTarget.Component.Owner == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (LastActor == Wielder.AimTarget.Component.Owner)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (!Wielder.AimTarget.bIsAutoAim)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (LastActor != Wielder.AimTarget.Component.Owner)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastActor = Wielder.AimTarget.Component.Owner;

		auto SapAimComponent = Cast<USapAutoAimTargetComponent>(Wielder.AimTarget.Component);
		if (SapAimComponent != nullptr)
		{
			switch(SapAimComponent.HighlightMode)
			{
				case ESapAutoAimHighlightMode::None:
					return;

				case ESapAutoAimHighlightMode::SpecificMeshes:
					HighlightMeshes(SapAimComponent.SpecificMeshesToHighlight);
					return;

				case ESapAutoAimHighlightMode::ParentMesh:
				{
					UMeshComponent Component = FindParentMesh(SapAimComponent);

					if (Component != nullptr)
					{
						TArray<UMeshComponent> Meshes;
						Meshes.Add(Component);

						HighlightMeshes(Meshes);
					}
					return;
				}

				case ESapAutoAimHighlightMode::ParentMeshRecursive:
				{
					TArray<UMeshComponent> Parents;
					FindParentMeshes(SapAimComponent, Parents);

					HighlightMeshes(Parents);
					return;
				}
			}
		}

		// If we get here, its either not a sap aim component, OR the 'All Meshes' option was specified,
		//	which is the same as a regular aim component
		TArray<UMeshComponent> Components;
		LastActor.GetComponentsByClass(Components);

		HighlightMeshes(Components);
	}

	UMeshComponent FindParentMesh(USceneComponent Leaf)
	{
		USceneComponent Comp = Leaf.GetAttachParent();

		while(Comp != nullptr)
		{
			auto CompMesh = Cast<UMeshComponent>(Comp);
			if (CompMesh != nullptr)
				return CompMesh;

			Comp = Comp.GetAttachParent();
		}

		return nullptr;
	}

	void FindParentMeshes(USceneComponent Leaf, TArray<UMeshComponent>& OutMeshes)
	{
		UMeshComponent Mesh = FindParentMesh(Leaf);

		while(Mesh != nullptr)
		{
			OutMeshes.Add(Mesh);
			Mesh = FindParentMesh(Mesh);
		} 
	}

	void HighlightMeshes(TArray<UMeshComponent> Meshes)
	{
		FOutline Outline;
		Outline.Tag = n"SapAutoAim";
		Outline.Color = FLinearColor(1.f, 0.2f, 0.2f, 1.f);
		Outline.BorderWidth = 6.f;
		Outline.BorderOpacity = 0.9f;
		Outline.FillOpacity = 0.15f;

		for(UMeshComponent Mesh : Meshes)
		{
			if (OutlineMeshes.Contains(Mesh))
				continue;

		 	CreateMeshOutline(Mesh, Outline);
		 	OutlineMeshes.Add(Mesh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveMeshOutline(n"SapAutoAim");

		LastActor = nullptr;
		OutlineMeshes.Empty();
	}
}