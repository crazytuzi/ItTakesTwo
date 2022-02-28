import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Peanuts.Triggers.HazeTriggerBase;

class ABlockDinoEatingOtherPlayerVolume : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Yellow);

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (Cast<AHeadButtingDino>(OtherActor) != nullptr)
		{
			DisableDinoCraneEatOtherPlayer(this);
		}
	}

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		if (Cast<AHeadButtingDino>(OtherActor) != nullptr)
		{
			EnableDinoCraneEatOtherPlayer(this);
		}
	}
}