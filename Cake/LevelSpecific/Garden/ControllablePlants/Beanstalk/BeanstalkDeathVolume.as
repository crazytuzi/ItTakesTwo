import Vino.Checkpoints.Volumes.DeathVolume;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class ABeanstalkDeathVolume : ADeathVolume
{
	UPROPERTY()
	float BeanstalkPushback = 800.0f;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor) override
    {
		ABeanstalk Beanstalk = Cast<ABeanstalk>(OtherActor);

		if(Beanstalk != nullptr)
		{
			HurtBeanstalk(Beanstalk);
			return;
		}
		else
		{
			UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(OtherActor);

			if(PlantsComp != nullptr 
			&& PlantsComp.CurrentPlant != nullptr
			&& PlantsComp.CurrentPlant.HasControl()
			&& PlantsComp.CurrentPlant.IsA(ABeanstalk::StaticClass()))
			{
				HurtBeanstalk(Cast<ABeanstalk>(PlantsComp.CurrentPlant));
				return;
			}
		}



		Super::ActorBeginOverlap(OtherActor);
    }

	private void HurtBeanstalk(ABeanstalk Beanstalk)
	{
		Beanstalk.Hurt(BeanstalkPushback);
	}
}
