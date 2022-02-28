import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AUnwitherBulbSpike : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent StaticMesh;

    UPROPERTY()
	float BlendTime = 2.0f;

    UPROPERTY()
	bool StartWithered = false;

    UPROPERTY(Category="DO NOT TOUCH")
	float TargetBlendValue = 0;

    UPROPERTY(Category="DO NOT TOUCH")
	float CurrentBlendValue = 0;

    UPROPERTY()
	bool bAddDelayBeforeUnwither = false;

    UPROPERTY()
	float DelayDuration = 1.0f;

	float DelayTimer = 0.0f;
	bool bDelayFinished = false;

	UFUNCTION(CallInEditor)
    void Wither()
    {
		TargetBlendValue = 1.0f;
	}
	UFUNCTION(CallInEditor)
    void UnWither()
    {
		TargetBlendValue = 0.0f;
	}
	UFUNCTION(CallInEditor)
    void WitherInstant()
    {
		TargetBlendValue = 1.0f;
		CurrentBlendValue = 1.0f;
	}
	UFUNCTION(CallInEditor)
    void UnWitherInstant()
    {
		TargetBlendValue = 0.0f;
		CurrentBlendValue = 0.0f;
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(StartWithered)
			WitherInstant();
		else
			UnWitherInstant();

		if(StartWithered)
			StaticMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CurrentBlendValue != TargetBlendValue)
		{
			if(bAddDelayBeforeUnwither && !bDelayFinished)
			{
				DelayTimer += DeltaTime;
				if(DelayTimer >= DelayDuration)
				{
					DelayTimer = 0.0f;
					bDelayFinished = true;
				}
				else
				{
					return;
				}
			}

			CurrentBlendValue = MoveTowards(CurrentBlendValue, TargetBlendValue, DeltaTime / BlendTime);
			StaticMesh.SetScalarParameterValueOnMaterials(n"BlendValue", CurrentBlendValue);
			
			if(CurrentBlendValue == TargetBlendValue)
			{
				if(CurrentBlendValue == 1.0f)
					StaticMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				else if(CurrentBlendValue == 0.0f)
					StaticMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			}
		}
	
	}
}