
struct FWitherMeshProperties
{
	UPROPERTY()
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY()
	AActor ActorData;

	UPROPERTY()
	float CurrentBlendValue = 0.f;
}

class APlayerUnwitherAreaManagerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AStaticMeshActor> ActorsToUnwither;
	TArray<AStaticMeshActor> ActorsToRemove;

	TArray<FWitherMeshProperties> ActorsCurrentlyWithering;
	TArray<FWitherMeshProperties> ActorsFinishedUnwithering;

	UPROPERTY(Category = "Setup")
	bool bShouldHideMeshesOnUpdated = false;

	UPROPERTY(Category = "Settings")
	bool bShouldUpdateForMay = true;

	UPROPERTY(Category = "Settings")
	bool bShouldUpdateForCody = true;

	UPROPERTY(Category = "Settings")
	float WitherDistance = 1500.f;

	float BlendTarget = 1.f;

	UPROPERTY(Category = "Settings")
	float BlendSpeed = 0.6f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto EditorBillboard = UBillboardComponent::Create(this);
		EditorBillboard.bIsEditorOnly = true;

		if(bShouldHideMeshesOnUpdated)
		{
			HidePickedActors();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ValidateDistanceToPlayers();
		SetWitherParam(DeltaSeconds);
		CleanupArrays();
	}

	void SetWitherParam(float DeltaTime)
	{
		for(int i = 0; i < ActorsCurrentlyWithering.Num(); i++)
		{
			if(ActorsCurrentlyWithering[i].CurrentBlendValue == BlendTarget)
				continue;
			
			float BlendValue = FMath::FInterpConstantTo(ActorsCurrentlyWithering[i].CurrentBlendValue, BlendTarget, DeltaTime, BlendSpeed);;
			ActorsCurrentlyWithering[i].CurrentBlendValue = BlendValue;
			ActorsCurrentlyWithering[i].DynamicMat.SetScalarParameterValue(n"BlendValue", BlendValue);

			if(BlendValue >= 1.f)
				ActorsFinishedUnwithering.Add(ActorsCurrentlyWithering[i]);
		}
	}

	void ValidateDistanceToPlayers()
	{
		FVector WitherLocation = FVector::ZeroVector;
		FVector DeltaVector = FVector::ZeroVector;

		for(int i = 0; i < ActorsToUnwither.Num(); i++)
		{
			WitherLocation = ActorsToUnwither[i].ActorLocation;

			if(bShouldUpdateForMay)
			{
				DeltaVector = Game::GetMay().ActorLocation - WitherLocation;

				if(DeltaVector.Size() < WitherDistance)
				{
					FWitherMeshProperties PropertyProfile;
					PropertyProfile.DynamicMat = ActorsToUnwither[i].StaticMeshComponent.CreateDynamicMaterialInstance(0);

					ActorsCurrentlyWithering.Add(PropertyProfile);
					ActorsToRemove.Add(ActorsToUnwither[i]);

					ActorsToUnwither[i].SetActorEnableCollision(false);
					continue;
				}
			}
			if(bShouldUpdateForCody)
			{
				DeltaVector = Game::GetCody().ActorLocation - WitherLocation;
				if(DeltaVector.Size() < WitherDistance)
				{
					FWitherMeshProperties PropertyProfile;
					PropertyProfile.DynamicMat = ActorsToUnwither[i].StaticMeshComponent.CreateDynamicMaterialInstance(0);

					ActorsCurrentlyWithering.Add(PropertyProfile);
					ActorsToRemove.Add(ActorsToUnwither[i]);

					ActorsToUnwither[i].SetActorEnableCollision(false);
					continue;
				}
			}
		}
	}

	UFUNCTION()
	void ActivateUnwitherChecks()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateUnwitherChecks()
	{
		SetActorTickEnabled(false);
	}

	void CleanupArrays()
	{
		if(ActorsToRemove.Num() != 0)
		{
			for(int i = 0; i < ActorsToRemove.Num(); i++)
			{
				ActorsToUnwither.Remove(ActorsToRemove[i]);
			}

			ActorsToRemove.Reset();
		}
		if(ActorsFinishedUnwithering.Num() != 0)
		{
			for(int i = 0; i < ActorsFinishedUnwithering.Num(); i++)
			{
				ActorsCurrentlyWithering.Remove(ActorsFinishedUnwithering[i]);
			}

			ActorsFinishedUnwithering.Reset();
		}
	}

	UFUNCTION(CallInEditor)
	void HidePickedActors()
	{
		for (auto MeshActor : ActorsToUnwither)
		{
			if(MeshActor != nullptr)
				MeshActor.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(CallInEditor)
	void ShowPickedActors()
	{
		for (auto MeshActor : ActorsToUnwither)
		{
			if(MeshActor != nullptr)
				MeshActor.SetActorHiddenInGame(false);
		}
	}
}