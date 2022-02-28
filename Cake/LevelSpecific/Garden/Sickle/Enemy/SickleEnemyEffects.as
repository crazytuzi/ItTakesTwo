
import void DeactivateDecal(ASickleEnemyEffectBloodDecal Decal) from "Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent"; 

UCLASS(Abstract)
class ASickleEnemyEffectBloodDecal : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeDecalComponent DecalComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000;
	default DisableComponent.bDisabledAtStart = false;
	default DisableComponent.bActorIsVisualOnly = true;

	// How long time until the decal is returned to the decal container
	UPROPERTY(EditDefaultsOnly)
	float LifeTime = 3.f;

	// How far from the actor, the blood will be spawned
	UPROPERTY(EditDefaultsOnly)
	FHazeMinMax RandomOffset = FHazeMinMax(80, 200);

	// At what random angles the blood will be spawned
	UPROPERTY(EditDefaultsOnly)
	FHazeMinMax RandomAngle = FHazeMinMax(-180, 180);

	float ActivationGameTime = 0;
	bool bIsShowingEffect = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		SetLifeSpan(-1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurrentTime = Time::GetGameTimeSeconds();
		if(CurrentTime >= ActivationGameTime + LifeTime)
		{
			DeactivateDecal(this);
		}
	}

	
	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		if(bIsShowingEffect)
		{
			DeactivateDecal(this);
		}
		return false;
	}

	UFUNCTION(BlueprintEvent)
	void StartAndShowEffect()
	{
		ActivationGameTime = Time::GetGameTimeSeconds();
		bIsShowingEffect = true;
	}
	
	UFUNCTION(BlueprintEvent)
	void EndAndHideEffect()
	{
		bIsShowingEffect = false;	
	}
}
