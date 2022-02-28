import Cake.LevelSpecific.Tree.Boat.TreeBoat;
import Cake.Weapons.Sap.SapWeaponNames;
import Vino.Interactions.Widgets.InteractionWidget;

class UTreeBoatComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UInteractionWidget> SapThrottleWidgetClass;

	UPROPERTY()
	UNiagaraSystem SapThrottleParticleSystem;

	UPROPERTY()
	UBlendSpace1D SapThrottleBlendSpace;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase TreeBoatSteeringFeature_Cody;

	UPROPERTY()
	UAnimSequence MayImpactAnimation;

	UPROPERTY()
	UAnimSequence CodyImpactAnimation;

	UPROPERTY()
	float ImpactDuration = 1.f;

	UPROPERTY()
	float SapEffectInterval = 0.01f;

	AHazePlayerCharacter Player;

	UPROPERTY()
	ATreeBoat ActiveTreeBoat;

	bool bInSapThrottleRange;
	bool bInWidgetRange;
	bool bIsKnockedDown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!System::IsValid(ActiveTreeBoat))
		{
			ActiveTreeBoat = nullptr;
			return;
		}

		float Distance = (Owner.GetActorLocation() - ActiveTreeBoat.GetActorLocation()).Size();

		bInWidgetRange = (Distance > 400.f && Distance < 800.f);
		bInSapThrottleRange = (Distance > 600.f && Distance < 800.f);
	}

	UFUNCTION()
	void KnockDownPlayer(ATreeBoat ImpactingTreeBoat, AActor OtherActor)
	{
	//	Print("KnockDown on " + ImpactingTreeBoat.GetName(), 5.f);

		if (ImpactingTreeBoat == ActiveTreeBoat)
			bIsKnockedDown = true;
	}

	UFUNCTION()
	void BindTreeBoat(ATreeBoat TreeBoat)
	{
		ActiveTreeBoat = TreeBoat;
		ActiveTreeBoat.OnTreeBoatImpact.AddUFunction(this, n"KnockDownPlayer");
		ActiveTreeBoat.Players.Add(Player);
	//	ActiveTreeBoat.OnEndPlay.AddUFunction(this, n"ActiveTreeBoatEndPlay");
	}

	UFUNCTION()
	void UnbindTreeBoat()
	{
		if(ActiveTreeBoat != nullptr)
		{
			ActiveTreeBoat.OnTreeBoatImpact.Unbind(this, n"KnockDownPlayer");
			ActiveTreeBoat.Players.Remove(Player);
		}
	//	ActiveTreeBoat.OnEndPlay.Unbind(this, n"ActiveTreeBoatEndPlay");
		ActiveTreeBoat = nullptr;
	}

	UFUNCTION()
	void ActiveTreeBoatEndPlay(AActor Actor, EEndPlayReason::Type Reason)
	{
		UnbindTreeBoat();
	}	

}