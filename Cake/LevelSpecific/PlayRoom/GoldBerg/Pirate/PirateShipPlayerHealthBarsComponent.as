import Peanuts.Health.HealthBarWidget;

class UPirateShipPlayerHealthBarsComponent : UActorComponent
{
    TArray<UHealthBarWidget> AvailablePool;

    UHealthBarWidget ShowHealthBar(TSubclassOf<UHealthBarWidget> WidgetClass)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
        UHealthBarWidget Widget;
        if (AvailablePool.Num() != 0)
        {
			for(int i = AvailablePool.Num() - 1; i >= 0; --i)
			{
				UHealthBarWidget ExistingWidget = AvailablePool[i];
                if (ExistingWidget.Class == WidgetClass.Get())
                {
                    Widget = ExistingWidget;
					Player.AddExistingWidget(Widget);  
               		AvailablePool.RemoveAtSwap(i);
                    break;
                }
            }
        }

        if (Widget == nullptr)
            Widget = Cast<UHealthBarWidget>(Player.AddWidget(WidgetClass.Get()));

        return Widget;
    }

    void HideHealthBar(UHealthBarWidget Widget)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
        Player.RemoveWidget(Widget);

        AvailablePool.Add(Widget);
    }
};
