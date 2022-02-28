import Vino.AI.GUI.EnemyIndicatorWidget;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;

class UWaspEffectsComponent : UActorComponent
{
	UPROPERTY(Category = "Effects")
    UNiagaraSystem ShakeOffEffect = Asset("/Game/Effects/Gameplay/Sap/Sap_Splat_System.Sap_Splat_System");
	
	UPROPERTY(Category = "Effects")
    UNiagaraSystem WaspDeathEffect = Asset("/Game/Effects/Gameplay/Wasps/WaspGibbingSystem.WaspGibbingSystem");

	UMaterialInterface FlashMaterial = Asset("/Game/Environment/Levelspecific/Shed/Swatches/Swatch_Red_Glowing_Eye_02.Swatch_Red_Glowing_Eye_02");
	float FlashTime = 0.f;

	UPROPERTY(Category = "GUI")
	TSubclassOf<UEnemyIndicatorWidget> IndicatorWidgetClass;

	private bool bDisplayAttack = false;
	private FVector DisplayAttackDestination = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UPrimitiveComponent> PrimitiveComponents;
		Owner.GetComponentsByClass(PrimitiveComponents);

		for (auto PrimitiveComponent : PrimitiveComponents)
		{
			PrimitiveComponent.SetReceivesDecals(false);
		}
	}

	void ShowAttackEffect(const FVector& Destination)
	{
		bDisplayAttack = true;
		DisplayAttackDestination = Destination;
	}
	void HideAttackEffect()
	{
		bDisplayAttack = false; 
	}
	bool ShouldShowAttackEffect()
	{
		return bDisplayAttack;
	}
	FVector GetDisplayedAttackDestination()
	{
		return DisplayAttackDestination;
	}

	void DeathEffect()
	{
		FVector SpawnLocation = Owner.ActorLocation;
		
		UHazeSkeletalMeshComponentBase SkelMesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		if (SkelMesh != nullptr)
			SpawnLocation = SkelMesh.GetSocketLocation(n"Hips");

		Niagara::SpawnSystemAtLocation(WaspDeathEffect, SpawnLocation, FRotator(0,0,0));
	}
}