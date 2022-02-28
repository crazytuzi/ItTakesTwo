class UHazeLightActionUtility : UActorActionUtility
{
	UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
		return ALight::StaticClass();
    }

	void GetAllLightsByMobility(TSubclassOf<AActor> LightClass, EComponentMobility Mobility, bool bOnlyShadowCasters = false)
	{
		TArray<AActor> LightsToSelect;

		TArray<AActor> AllLights;
		Gameplay::GetAllActorsOfClass(LightClass.Get(), AllLights);

		for (AActor Light : AllLights)
		{
			ULightComponent LightComponent = Cast<ULightComponent>(Light.GetRootComponent());
			if (bOnlyShadowCasters && !LightComponent.CastShadows)
				continue;

			if (LightComponent.Mobility == Mobility)
				LightsToSelect.Add(Light);
		}
		EditorLevel::SetSelectedLevelActors(LightsToSelect);
	}

	UFUNCTION(CallInEditor, Category = "Static Light Actions")
    void SelectAllStatic()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ALight::StaticClass()), EComponentMobility::Static);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectAllStationary()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ALight::StaticClass()), EComponentMobility::Stationary);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectAllShadowCastingStationary()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ALight::StaticClass()), EComponentMobility::Stationary, true);
	}

	UFUNCTION(CallInEditor, Category = "Movable Light Actions")
    void SelectAllMovable()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ALight::StaticClass()), EComponentMobility::Movable);
	}

	// So much code I'm having to steal as it's not exposed to .as, here I reimplement the GetBoundingSphere for Lights,
	FBoxSphereBounds GetLightBounds(ALight Light)
	{
		FBoxSphereBounds Bounds;

		if (Light.Class == APointLight::StaticClass())
		{
			UPointLightComponent PointLightComponent = Cast<UPointLightComponent>(Light.GetRootComponent()); 
			Bounds.SphereRadius = PointLightComponent.GetAttenuationRadius();
			Bounds.Origin = Light.GetActorLocation();
			Bounds.BoxExtent = FVector::OneVector * FMath::Sqrt(Bounds.SphereRadius);
		}

		if (Light.Class == ASpotLight::StaticClass())
		{
			USpotLightComponent SpotLightComponent = Cast<USpotLightComponent>(Light.GetRootComponent()); 
			
			// GetHalfConeAngle not exposed so we're making it ourselves,
			float ClampedInnerConeAngle = FMath::Clamp(SpotLightComponent.GetInnerConeAngle(), 0.0f, 89.0f) * PI / 180.0f;
			float ConeAngle = FMath::Clamp(SpotLightComponent.GetOuterConeAngle() * PI / 180.0f, ClampedInnerConeAngle + 0.001f, 89.0f * PI / 180.0f + 0.001f);

			float CosConeAngle = FMath::Cos(ConeAngle);
			float SinConeAngle = FMath::Sin(ConeAngle);

			// And here we reimplement ComputeBoundingSphereForCone
			const float COS_PI_OVER_4 = 0.70710678118f;

			FVector ConeOrigin = Light.GetActorLocation();
			FVector ConeDirection = Light.GetActorForwardVector();
			float ConeRadius = SpotLightComponent.GetAttenuationRadius();

			if (CosConeAngle < COS_PI_OVER_4)
			{
				Bounds.Origin = ConeOrigin + ConeDirection * ConeRadius * CosConeAngle;
				Bounds.SphereRadius = ConeRadius * SinConeAngle;
				Bounds.BoxExtent = FVector::OneVector * FMath::Sqrt(Bounds.SphereRadius);
			}
			else
			{
				const float BoundingRadius = ConeRadius / (2.0f * CosConeAngle);
				Bounds.Origin = ConeOrigin + ConeDirection * BoundingRadius;
				Bounds.SphereRadius = BoundingRadius;
				Bounds.BoxExtent = FVector::OneVector * FMath::Sqrt(Bounds.SphereRadius);
			}

		}

		// If we want to implement for directional light, the bounds are infinite so just say yes...

		return Bounds;
	}

	// Going to steal some code like a good robber from the LightMass for checking if lights are
	// overlapping.
	bool Overlaps(ALight Caster, ALight Reciever)
	{

		FBoxSphereBounds Bounds = GetLightBounds(Reciever); // In a perfect world, the bounds would be exposed so we can get them but alas.

		if (Caster.Class == APointLight::StaticClass())
		{
			UPointLightComponent CasterComponent = Cast<UPointLightComponent>(Caster.GetRootComponent()); // no to null check yo
			if ( (Bounds.Origin - Caster.GetActorLocation()).SizeSquared() > FMath::Square(CasterComponent.GetAttenuationRadius() + Bounds.SphereRadius) )
			{
				return false;
			}
			return true;
		}

		if (Caster.Class == ASpotLight::StaticClass())
		{
			USpotLightComponent CasterComponent = Cast<USpotLightComponent>(Caster.GetRootComponent());
			
			// Radial Check, same as for checking points lights,
			if ( (Bounds.Origin - Caster.GetActorLocation()).SizeSquared() > FMath::Square(CasterComponent.GetAttenuationRadius() + Bounds.SphereRadius) )
			{
				return false;
			}

			// Calculate stuff for the cones I guess,

			// Make mathematician code verboten :(((

			FVector U = Caster.GetActorLocation() - FVector( Bounds.SphereRadius / FMath::Sin( CasterComponent.GetOuterConeAngle() ) ) * CasterComponent.GetForwardVector();
			FVector D = Bounds.Origin - U;

			float dsqr = D.DotProduct(D);
			float E = CasterComponent.GetForwardVector().DotProduct(D);

			if ( E > 0.0f && E * E >= dsqr * FMath::Square(FMath::Cos( CasterComponent.GetOuterConeAngle() )) )
			{
				D = Bounds.Origin - Caster.GetActorLocation();
				dsqr = D.DotProduct(D);
				E = -E;
				if (E > 0.0f && E * E >= dsqr * FMath::Square(FMath::Sin( CasterComponent.GetOuterConeAngle() )))
					return dsqr <= FMath::Square(Bounds.SphereRadius);
				else
					return true;
			}

			return false;
		}

		return false;
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
	void SelectOverlappingStationaryLights()
	{
		TArray<AActor> AllLights;
		Gameplay::GetAllActorsOfClass(ALight::StaticClass(), AllLights);

		TArray<AActor> LightsToSelect;

		for (AActor Actor: EditorUtility::GetSelectionSet())
		{
			// Cast and skip for any selected actor that is not a light,
			ALight SelectedLight = Cast<ALight>(Actor);
			if (SelectedLight == nullptr)
				continue;

			// Skip any selected light that is not 'Stationary'
			if (SelectedLight.GetRootComponent().Mobility != EComponentMobility::Stationary)
				continue;

			for (AActor Other: AllLights)
			{
				if (Actor == Other)
					continue; // We don't want to check with ourselves,

				if (Other.GetRootComponent().Mobility != EComponentMobility::Stationary)
					continue; // Skip any lights that isn't stationary

				ALight OtherLight = Cast<ALight>(Other);

				if (Overlaps(SelectedLight, OtherLight) && Overlaps(OtherLight, SelectedLight))
					LightsToSelect.Add(Other);
			}
		}

		EditorLevel::SetSelectedLevelActors(LightsToSelect);
	}
}