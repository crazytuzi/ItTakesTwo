
UFUNCTION()
void Flash(UPrimitiveComponent Mesh, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{
	// Loop through all materials on the mesh and trigger the flash.
	for (int i = 0; i < Mesh.GetNumMaterials(); i++)
	{
		if (Mesh.GetMaterial(i) == nullptr)
			continue;
		auto MatInst = Mesh.CreateDynamicMaterialInstance(i);
		if (MatInst == nullptr)
			continue;
		
		MatInst.SetScalarParameterValue(n"FlashTime", Time::GetGameTimeSeconds());
		MatInst.SetScalarParameterValue(n"FlashDuration", Duration);
		MatInst.SetVectorParameterValue(n"FlashColor", Color);
	}
}

UFUNCTION()
void ClearFlash(UPrimitiveComponent Mesh)
{
	// Loop through all materials on the mesh and trigger the flash.
	for (int i = 0; i < Mesh.GetNumMaterials(); i++)
	{
		if (Mesh.GetMaterial(i) == nullptr)
			continue;
		auto MatInst = Mesh.CreateDynamicMaterialInstance(i);
		if (MatInst == nullptr)
			continue;
		
		MatInst.SetScalarParameterValue(n"FlashTime", 0.f);
		MatInst.SetScalarParameterValue(n"FlashDuration", 0.f);
		MatInst.SetVectorParameterValue(n"FlashColor", FLinearColor::Transparent);
	}
}

UFUNCTION()
void FlashMaterialIndex(UPrimitiveComponent Mesh, int MaterialIndex, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{ 
	auto MatInst = Mesh.CreateDynamicMaterialInstance(MaterialIndex);
	if (MatInst == nullptr)
		return;
	
	MatInst.SetScalarParameterValue(n"FlashTime", Time::GetGameTimeSeconds());
	MatInst.SetScalarParameterValue(n"FlashDuration", Duration);
	MatInst.SetVectorParameterValue(n"FlashColor", Color);
}


// Will find components on the actor and cause them to flash
UFUNCTION()
void FlashActor(AHazeActor Actor, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{
	TArray<UMeshComponent> MeshComponents; 
	Actor.GetComponentsByClass(MeshComponents);

	for (UMeshComponent MeshComponent : MeshComponents)
	{
		Flash(MeshComponent, Duration, Color);
	}
}

UFUNCTION()
void FlashPlayer(AHazePlayerCharacter Player, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{
	// Flash all components attached to the player's mesh
	TArray<USceneComponent> Comps;
	Comps.Reserve(32);
	Comps.Add(Player.Mesh);

	int CheckIndex = 0;
	while (CheckIndex < Comps.Num())
	{
		USceneComponent Comp = Comps[CheckIndex];

		// Flash any meshes that are attached
		auto MeshComp = Cast<UMeshComponent>(Comp);
		if (MeshComp != nullptr)
			Flash(MeshComp, Duration, Color);

		// Recurse through children of this component
		for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
		{
			auto Child = Comp.GetChildComponent(i);
			if (Child != nullptr)
				Comps.AddUnique(Child);
		}

		CheckIndex += 1;
	}
}

UFUNCTION()
void ClearPlayerFlash(AHazePlayerCharacter Player)
{
	// Flash all components attached to the player's mesh
	TArray<USceneComponent> Comps;
	Comps.Reserve(32);
	Comps.Add(Player.Mesh);

	int CheckIndex = 0;
	while (CheckIndex < Comps.Num())
	{
		USceneComponent Comp = Comps[CheckIndex];

		// Flash any meshes that are attached
		auto MeshComp = Cast<UMeshComponent>(Comp);
		if (MeshComp != nullptr)
			ClearFlash(MeshComp);

		// Recurse through children of this component
		for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
		{
			auto Child = Comp.GetChildComponent(i);
			if (Child != nullptr)
				Comps.AddUnique(Child);
		}

		CheckIndex += 1;
	}
}