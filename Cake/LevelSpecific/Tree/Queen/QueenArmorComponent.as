import Cake.LevelSpecific.Tree.Queen.QueenArmorHealthWidget;
import Cake.Weapons.AimTargetIndicator.AimTargetIndicatorComponent;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;

event void FOnArmorDestroyed(UQueenArmorComponent Armor, bool CauseSpecialAttack, bool PlaySpecialEffects);

// we get a serialization crash when we open queen, 
// if we switch to inheriting from the scenecomponent instead
class UQueenArmorComponent : UStaticMeshComponent
{
	// Disable various things due to us not being able to change inheritance
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default SetComponentTickEnabled(false);
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default bHiddenInGame = true;
	default CastShadow = false;

	UPROPERTY(BlueprintReadWrite, Category = "Armor")
    float HP = 100.f;

	UPROPERTY(BlueprintReadWrite, Category = "Armor")
	float MaxHealth = 100.f;

	UPROPERTY(BlueprintReadWrite, Category = "Armor")
	bool IgnoreDamage;

	UPROPERTY(BlueprintReadWrite, Category = "Armor")
	bool bIsEndingArmor;

	UPROPERTY()
	int MaterialIndex;

	UPROPERTY()
	FOnArmorDestroyed OnArmorDestroyed;

	UPROPERTY()
	TArray<FName> SocketNames;

	UPROPERTY()
	UAnimSequence DetachfromQueenAnimToPlay;

	UPROPERTY()
	UAnimSequence OnHitAnimation;

	bool DetachedFromQueen = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HP = MaxHealth;

		if(!bIsEndingArmor)
		{
			AddAimIndicatorTarget(Game::GetMay(), this);
			AddAimIndicatorTarget(Game::GetCody(), this);
		}
	}

	UFUNCTION()
	void ActivateEndingArmorIcon()
	{
		AddAimIndicatorTarget(Game::GetMay(), this);
		AddAimIndicatorTarget(Game::GetCody(), this);
	}

	UFUNCTION(NetFunction)
	void NetDetachFromQueen(bool CauseSpecialAttack, bool PlayEffects = true)
	{
		DetachFromQueen(CauseSpecialAttack, PlayEffects);
	}

	void DetachFromQueen(bool CauseSpecialAttack, bool PlayEffects = true)
	{
		if (!DetachedFromQueen)
		{
			HP = 0;
			DetachedFromQueen = true;
			USapAutoAimTargetComponent SapAutoAim = Cast<USapAutoAimTargetComponent>(this.GetChildComponent(0));
			SapAutoAim.bIsAutoAimEnabled = false;
			OnArmorDestroyed.Broadcast(this, CauseSpecialAttack, PlayEffects);
		}
	}
		 
}