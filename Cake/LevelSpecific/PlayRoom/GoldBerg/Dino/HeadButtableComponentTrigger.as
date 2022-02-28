import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.HeadbuttingDinoActivationPoint;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoButton;

class AheadButtableComponentTrigger: AVolume
{
	TArray<UHeadButtableComponent> HeadButtableComponents;

	UPROPERTY()
	TArray<AActor> HeadButtableActors;

	UPROPERTY(DefaultComponent)
	UHeadbuttingDinoActivationPoint ActivationPoint;

	UPROPERTY()
	ADinoButton Button;

	AHeadButtingDino OverlappingDino;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor Actor : HeadButtableActors)
		{
			if (Actor == nullptr)
				continue;

			UHeadButtableComponent HeadbuttableComponent = UHeadButtableComponent::Get(Actor);

			if (HeadbuttableComponent != nullptr)
			{
				HeadButtableComponents.Add(HeadbuttableComponent);
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHeadButtingDino Dino = Cast<AHeadButtingDino>(OtherActor);
		
        if(Dino != nullptr)
		{
			OverlappingDino = Dino;

			if (OverlappingDino.HasControl())
			{
				OverlappingDino.OverlappingHeadButtableComponents = HeadButtableComponents;
				OverlappingDino.HeadbuttTrigger = this;
			}
			
		}
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHeadButtingDino Dino = Cast<AHeadButtingDino>(OtherActor);

        if(Dino != nullptr)
		{
			if (OverlappingDino.HasControl())
			{
				OverlappingDino.OverlappingHeadButtableComponents.Empty();
				OverlappingDino.HeadbuttTrigger = nullptr;
			}
			OverlappingDino = nullptr;
		}
    }
}