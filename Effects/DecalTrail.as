// Spawns decals as the it moves around.
class UDecalTrailComponent : USceneComponent
{
	UPROPERTY()
	float DecalWidth = 25;

	UPROPERTY()
	float DecalLength = 100;

	UPROPERTY()
	float DecalHeight = 25;
	
	UPROPERTY()
	UMaterialInterface DecalMaterial;

	UPROPERTY()
	int MaxDecals = 100;
	
	UPROPERTY()
	float DecalLifetime = 0.f;

	UPROPERTY()
	FVector SnapLocation;

	UPROPERTY()
	TArray<UDecalComponent> SpawnedDecals = TArray<UDecalComponent>();

	UPROPERTY()
	UDecalComponent CurrentDecal;

	UPROPERTY()
	UMaterialInstanceDynamic CurrentDecalMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnapLocation = GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(auto Decal : SpawnedDecals)
		{
			if (Decal == nullptr || Decal.IsBeingDestroyed())
				continue;

			Decal.DestroyComponent(Decal);
		}

		SpawnedDecals.Empty();
	} 

	float GlobalDecalFade = 0;
	float GlobalDecalFadeTotal = 0;
	// Removes all spawned decals
	UFUNCTION()
	void Clear(float FadeTime = 0.0f)
	{
		GlobalDecalFade = FadeTime + 0.001f;
		GlobalDecalFadeTotal = GlobalDecalFade;
	}

	void ClearTrailImmediate()
	{
		GlobalDecalFade = 0;
		for (int i = 0; i < SpawnedDecals.Num(); i++)
		{
			if(SpawnedDecals[i] != nullptr)
				SpawnedDecals[i].DestroyComponent(SpawnedDecals[i]);
		}
	}

	// When clear is called this function is used to slowly fade the whole thing out.
	void GlobalFade(float DeltaTime)
	{
		if(GlobalDecalFade > 0) // If it's larger than 0, fade down.
		{
			GlobalDecalFade -= DeltaTime;
			float Opacity = GlobalDecalFade / GlobalDecalFadeTotal;
			
			for (int i = 0; i < SpawnedDecals.Num(); i++)
			{
				if(SpawnedDecals[i] == nullptr)
					continue;
				auto MattDamon = SpawnedDecals[i].GetDecalMaterial();
				UMaterialInstanceDynamic MaterialInstance = Cast<UMaterialInstanceDynamic>(MattDamon);

				if (MaterialInstance == nullptr)
					continue;

				MaterialInstance.SetScalarParameterValue(n"DecalTrailClearFade", Opacity);
			}
				
		}
		else if(GlobalDecalFade < 0) // on the frame where it went below 0, set it to exactly 0 so it stops changing.
		{
			GlobalDecalFade = 0;
			for (int i = 0; i < SpawnedDecals.Num(); i++)
			{
				if(SpawnedDecals[i] != nullptr)
					SpawnedDecals[i].DestroyComponent(SpawnedDecals[i]);
			}
		}
	}

	// Each tick we want to reduce the decal lifetime by x amount,
	void DecayOverTime(float Decay)
	{
		if (SpawnedDecals.Num() == 0) {
			return;
		}

		if (DecalLifetime <= 0.f) { // Live forever,
			return;
		}

		float PreviousDecalValue = 0;
		for (UDecalComponent DecalComponent : SpawnedDecals)
		{
			if (DecalComponent == nullptr)
				continue;

			// Get the material for the decal, checking for null,
			auto MattDamon = DecalComponent.GetDecalMaterial();
			UMaterialInstanceDynamic MaterialInstance = Cast<UMaterialInstanceDynamic>(MattDamon);
			if (MaterialInstance == nullptr)
				continue;
				
			// Set and update the current value,
			float Value = MaterialInstance.GetScalarParameterValue(n"DecalTrailLifetime");
			Value = FMath::Max(0.f, Value - (Decay / DecalLifetime));
			MaterialInstance.SetScalarParameterValue(n"DecalTrailLifetime", Value);
			MaterialInstance.SetScalarParameterValue(n"PreviousDecalTrailLifetime", PreviousDecalValue);
			PreviousDecalValue = Value;
		} 
	}

	// Each tick we want to update the parameter for the decals in our array, so first decal if 1.f and last 0.f
	void DecayOverTrail()
	{
		if (SpawnedDecals.Num() == 0)
			return;		

		float Value = 1.f / MaxDecals; // The value to increment for each decal,
		float CurrentValue = 1.0f; // Starting value for 'last' decal in queue,
		float PreviousValue = 1.0f;

		// Iterate over spawned decals, going from last spawned to earliest available,
		for (int i = SpawnedDecals.Num() - 1; i >= 0; i--)
		{
			if (SpawnedDecals[i] == nullptr)
				continue;
				
			UMaterialInstanceDynamic MaterialInstance = Cast<UMaterialInstanceDynamic>(SpawnedDecals[i].GetDecalMaterial());
			if (MaterialInstance == nullptr)
				continue;

			float Offset = 1.f - GetWorldLocation().Distance(SnapLocation) / DecalLength;

			MaterialInstance.SetScalarParameterValue(n"DecalTrailFade", CurrentValue + Value*Offset);
			MaterialInstance.SetScalarParameterValue(n"PreviousDecalTrailFade", PreviousValue + Value*Offset);
			PreviousValue = CurrentValue;			
			CurrentValue = FMath::Max(0.f, CurrentValue - Value);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(DecalMaterial == nullptr)
			return;

		if(CurrentDecalMaterial == nullptr)
		{
			CurrentDecal = Gameplay::SpawnDecalAtLocation(DecalMaterial, FVector::OneVector, FVector::ZeroVector);
			CurrentDecalMaterial = CurrentDecal.CreateDynamicMaterialInstance();
			SpawnedDecals.Add(CurrentDecal);
		}

		if(CurrentDecal != nullptr)
		{
			FVector CenterPoint = (SnapLocation + GetWorldLocation()) * 0.5f;
			FVector ForawrdVector = GetWorldLocation() - SnapLocation;
			float Distance = ForawrdVector.Size();
			ForawrdVector.Normalize();
			FRotator DecalRotation = Math::MakeRotFromZX(ForawrdVector, -GetWorldRotation().GetUpVector());

			CurrentDecal.SetWorldLocation(CenterPoint);
			CurrentDecal.SetWorldRotation(DecalRotation);
			CurrentDecal.SetRelativeScale3D(FVector(DecalWidth, DecalHeight, Distance * 0.5f));
			CurrentDecalMaterial.SetScalarParameterValue(n"DecalTrailYScale", (Distance / DecalLength));
		}

		if(GetWorldLocation().Distance(SnapLocation) > DecalLength)
		{
			SnapLocation = GetWorldLocation();
			CurrentDecal = Gameplay::SpawnDecalAtLocation(DecalMaterial, FVector::OneVector, FVector::ZeroVector);
			CurrentDecalMaterial = CurrentDecal.CreateDynamicMaterialInstance();
			SpawnedDecals.Add(CurrentDecal);
			if(SpawnedDecals.Num() > MaxDecals)
			{
				UDecalComponent LastDecal = SpawnedDecals[0];
				if(LastDecal != nullptr)
					LastDecal.DestroyComponent(LastDecal);
				SpawnedDecals.RemoveAt(0);
			}
		}

		// Update existing decals,
		DecayOverTime(DeltaTime);
		DecayOverTrail();
		GlobalFade(DeltaTime);
	}
}