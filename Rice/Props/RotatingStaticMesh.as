class ARotatingStaticMesh : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent StaticMeshComponent;
	default StaticMeshComponent.SetCastShadow(false);

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovement;
	default RotatingMovement.bUpdateOnlyIfRendered = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;
	default DisableComponent.bActorIsVisualOnly = true;

#if EDITOR
	UFUNCTION(CallInEditor)
	void ConvertStaticMeshActors()
	{
		for (AActor Actor : Level.Actors)
		{
			AStaticMeshActor StaticMeshActor = Cast<AStaticMeshActor>(Actor);
			if (StaticMeshActor == nullptr)
				continue;

			TArray<UActorComponent> Comps;
			StaticMeshActor.GetComponentsByClass(Comps);
			if (Comps.Num() != 2)
				continue;

			UStaticMeshComponent MeshComp = UStaticMeshComponent::Get(StaticMeshActor);
			URotatingMovementComponent RotComp = URotatingMovementComponent::Get(StaticMeshActor);

			if (MeshComp == nullptr || RotComp == nullptr)
				continue;

			ARotatingStaticMesh NewActor = Cast<ARotatingStaticMesh>(SpawnActor(
				ARotatingStaticMesh::StaticClass(),
				Location = StaticMeshActor.ActorLocation,
				Rotation = StaticMeshActor.ActorRotation,
				Level = GetLevel(),
				Name = FName("Rotating_"+StaticMeshActor.Name)
			));

			NewActor.RotatingMovement.RotationRate = RotComp.RotationRate;
			NewActor.RotatingMovement.PivotTranslation = RotComp.PivotTranslation;
			NewActor.RotatingMovement.bRotationInLocalSpace = RotComp.bRotationInLocalSpace;

			NewActor.StaticMeshComponent.StaticMesh = MeshComp.StaticMesh;
			NewActor.StaticMeshComponent.SetCullDistance(MeshComp.LDMaxDrawDistance);

			NewActor.SetActorScale3D(StaticMeshActor.ActorScale3D);
			NewActor.ActorLabel = "Rotating_"+StaticMeshActor.Name;

			StaticMeshActor.DestroyActor();
		}
	}
#endif
};