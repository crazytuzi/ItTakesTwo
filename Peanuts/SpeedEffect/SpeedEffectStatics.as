import Peanuts.SpeedEffect.SpeedEffectComponent;

namespace SpeedEffect
{
	UFUNCTION()
	void RequestSpeedEffect(AHazePlayerCharacter Player, FSpeedEffectRequest Request)
	{
		USpeedEffectComponent SpeedEffectComp = USpeedEffectComponent::Get(Player);

		if (SpeedEffectComp == nullptr)
			return;
		
		SpeedEffectComp.RequestValue(Request);
	}
}