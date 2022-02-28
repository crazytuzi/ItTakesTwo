// For example, we can make a new Actor class
class ABalloonThrusterFlames : AHazeActor
{
	UPROPERTY()
	float Strength = 0.5;

	UPROPERTY()
    UParticleSystemComponent Effect;
    
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        Log("asdf");
	}

    FParticleSysParam ParticleFloatParam(FString ParticleName, float Value)
    {
        FParticleSysParam Result = FParticleSysParam();
        Result.Name = FName(ParticleName);
        Result.Scalar = Value;
        Result.ParamType = EParticleSysParamType::PSPT_Scalar;
        return Result;
    }

    FParticleSysParam ParticleVectorParam(FString ParticleName, FVector Value)
    {
        FParticleSysParam Result = FParticleSysParam();
        Result.Name = FName(ParticleName);
        Result.Vector = Value;
        Result.ParamType = EParticleSysParamType::PSPT_Vector;
        return Result;
        
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        
        if(Effect != nullptr)
        {
            float time = Time::GetRealTimeSeconds();
            //Strength = (FMath::Sin(time) + 1.0) * 0.5;
            Strength = 1.0 - (FMath::Pow(((FMath::Sin(time) + 1.0)) / 2.0, 2.0));

            float noise = ((Strength % 1.0 / 4.0) * 4.0);
            float FlameRegion = FMath::Clamp((1.0 - (((Strength - 0.5) * (Strength - 0.5)) * 6.0))-0.5, 0.0, 1.0);
            float FlameStrength = noise * FlameRegion + (FlameRegion * 0.5);
            
            //float JetStrength = FMath::Clamp(Strength-0.2, 0.0, 1.0) * FMath::Clamp(Strength-0.2, 0.0, 1.0);
			float JetStrength = FMath::Pow(Strength-0.5,0.125)*1.1;
            float BlueFlameStrength = 1.0 - (11.0 * FMath::Pow((Strength-0.2),2.0));

            float DripAmount = (1.0 - (((Strength - 0.25) * (Strength - 0.25)) * 16.0));
            float DripStrength = Strength * Strength * 1;

            TArray<FParticleSysParam> ParticleParameters;

            ParticleParameters.Add(ParticleFloatParam("DripAmount", DripAmount));
            ParticleParameters.Add(ParticleVectorParam("DripVelocity", FVector(DripStrength, 0.0, 0.0)));

            ParticleParameters.Add(ParticleVectorParam("FlameVelocity", FVector(1.0, 0.0, 0.0)));
            ParticleParameters.Add(ParticleFloatParam("FlameSpawnRate", FlameStrength));

            ParticleParameters.Add(ParticleFloatParam("JetSpawnRate", JetStrength));
            ParticleParameters.Add(ParticleVectorParam("JetSpawnRate", FVector(JetStrength, 0.0, 0.0)));
            ParticleParameters.Add(ParticleFloatParam("BlueFlameStrength", BlueFlameStrength));
            ParticleParameters.Add(ParticleVectorParam("BlueFlameStrength", FVector(BlueFlameStrength, 0.0, 0.0)));

            Effect.InstanceParameters = ParticleParameters;
        }
    }
};