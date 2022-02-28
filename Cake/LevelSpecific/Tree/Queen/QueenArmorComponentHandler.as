import Cake.LevelSpecific.Tree.Queen.QueenArmorComponent;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;
import Peanuts.Health.BossHealthBarWidget;

event void FQueenArmorDetached(UQueenArmorComponent ArmorPieceRemoved, int NumRemainingArmorPieces, bool CauseSpecialAttack);
class UQueenArmorComponentHandler : UActorComponent
{
	UPROPERTY()
	TArray<UQueenArmorComponent> TotalArmorComponents;

	UPROPERTY()
	TArray<UQueenArmorComponent> HealthyArmorComponents;

	UPROPERTY(Category = "Widget")
	TSubclassOf<UBossHealthBarWidget> BossHealthbarWidgetClass;

	UPROPERTY()
	FQueenArmorDetached OnQueenArmorDetached;

	UFUNCTION()
	void Setup()
	{
		Owner.GetComponentsByClass(TotalArmorComponents);

		for (UQueenArmorComponent Armor : TotalArmorComponents)
		{
			Armor.OnArmorDestroyed.AddUFunction(this, n"OnArmorDestroyed");
		}

		for (UQueenArmorComponent Armor : TotalArmorComponents)
		{
			if (!Armor.bIsEndingArmor)
			{
				HealthyArmorComponents.Add(Armor);
			}
		}
		HideEndingArmor();
	}

	void HideEndingArmor()
	{
		for (UQueenArmorComponent Armor : TotalArmorComponents)
		{
			if(Armor.bIsEndingArmor)
			{
				Armor.SetVisibility(false);
				Armor.IgnoreDamage = true;
				USapAutoAimTargetComponent SapAutoAim = Cast<USapAutoAimTargetComponent>(Armor.GetChildComponent(0));
				SapAutoAim.bIsAutoAimEnabled = false;
			}
		}
	}

	UFUNCTION()
	void ActivateEndingArmor()
	{
		HealthyArmorComponents.Empty();

		for (UQueenArmorComponent Armor : TotalArmorComponents)
		{
			if (Armor.bIsEndingArmor)
			{
				HealthyArmorComponents.Add(Armor);
				Armor.SetVisibility(true);
				Armor.IgnoreDamage = false;
				Armor.ActivateEndingArmorIcon();

				USapAutoAimTargetComponent SapAutoAim = Cast<USapAutoAimTargetComponent>(Armor.GetChildComponent(0));
				SapAutoAim.bIsAutoAimEnabled = true;
			}
		}
	}

	UFUNCTION()
	void OnArmorDestroyed(UQueenArmorComponent Armor, bool CauseSpecialAttack, bool PlayEffects)
	{
		HealthyArmorComponents.Remove(Armor);
		OnQueenArmorDetached.Broadcast(Armor, HealthyArmorComponents.Num(), CauseSpecialAttack);
	}

	UFUNCTION()
	void RemoveArmorPieces(TArray<UQueenArmorComponent> ArmorComponents)
	{
		for (UQueenArmorComponent ArmorComp : ArmorComponents)
		{
			HealthyArmorComponents.Remove(ArmorComp);
			ArmorComp.NetDetachFromQueen(false, false);
		}
	}
}