import Cake.DebugMenus.Audio.GraphWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuTabWidget;
import Cake.DebugMenus.Audio.AudioDebugMenuRTPCListItem;
import Cake.DebugMenus.Audio.AudioDebugViewportWidget;

class UAudioDebugMenuRTPCWidget : UAudioDebugMenuTabWidget
{
	UPanelWidget OriginalParent;
	UAudioDebugViewportWidget ViewportWidget;

	UPROPERTY()
	TSubclassOf<UAudioDebugMenuRTPCListItem> ItemWidgetClass;
	private UAudioDebugMenuRTPCListItem StaticItem;

	UFUNCTION(BlueprintEvent)
	UGraphWidget GetGraphWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UVerticalBox GetVerticalBox() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void OnUpdateTexts() { }

	// bUseRTPCs, Because i'm lazy i.e not creating another widget.
	void Setup(UAudioDebugViewportWidget Viewport, bool bUseRTPCs)
	{
		ViewportWidget = Viewport;
		if (bUseRTPCs) 
		{
			StaticItem = Cast<UAudioDebugMenuRTPCListItem>(
					Widget::CreateWidget(this, ItemWidgetClass)
					);
			StaticItem.Setup(this, n"", FLinearColor::Black, true);
			VerticalBox.AddChild(StaticItem);
		}

		ToggleViewports();
	}

	UFUNCTION()
	void ToggleViewports() 
	{
		if (OriginalParent == nullptr)
		{
			OriginalParent = GetParent();
			ViewportWidget.AddChild(this);
		}
		else {
			OriginalParent.AddChild(this);
			OriginalParent = nullptr;
		}
	}

	UFUNCTION()
	void OnAddRTPC(UAudioDebugMenuRTPCListItem Item)
	{
		FString RtpcName = Item.EditableText.Text.ToString();

		FLinearColor Color;
		if (!GraphWidget.Add(RtpcName, Color))
			return;

		//Make a copy of the data, and create a new one.
		UAudioDebugMenuRTPCListItem NewItem = Cast<UAudioDebugMenuRTPCListItem>(
				Widget::CreateWidget(this, ItemWidgetClass)
				);

		NewItem.Setup(this, FName(RtpcName), Color);
		NewItem.ElementData.Actor = Item.ElementData.Actor;
		NewItem.ElementData.PlayingId = Item.ElementData.PlayingId;
		NewItem.ElementData.RTPCType = 	Item.ElementData.RTPCType;

		FString ActorName = "";
		if (NewItem.ElementData.Actor != nullptr)
			ActorName = NewItem.ElementData.Actor.Name.ToString().Contains("May") ? "May" : "Cody";

		NewItem.OnForceSelectionChange(
			NewItem.ElementData.RTPCType == ERTPCValueType::GameObject ? "Player" : "Global",
			ActorName);
		VerticalBox.AddChild(NewItem);
	}

	UFUNCTION()
	void OnRemoveRTPC(UAudioDebugMenuRTPCListItem Item)
	{
		if (GraphWidget != nullptr) 
		{
			GraphWidget.Remove(Item.ElementData.RTPCName.ToString());
		}

		VerticalBox.RemoveChild(Item);
	}

	UFUNCTION()
	void AddRTPC(FString RTPC)
	{
		FLinearColor Color;
		if (!GraphWidget.Add(RTPC, Color))
			return;

		UAudioDebugMenuRTPCListItem Item = Cast<UAudioDebugMenuRTPCListItem>(
				Widget::CreateWidget(this, ItemWidgetClass)
				);

		Item.Setup(this, FName(RTPC), Color);
		VerticalBox.AddChild(Item);
	}

	UFUNCTION()
	void RemoveRTPC(FString RTPC) 
	{
		if (GraphWidget != nullptr) 
		{
			GraphWidget.Remove(RTPC);
		}

		FName RTPCName = FName(RTPC);
		for	(auto ItemObject: VerticalBox.GetAllChildren())
		{
			UAudioDebugMenuRTPCListItem Item = Cast<UAudioDebugMenuRTPCListItem>(ItemObject);
			if (Item.ElementData.RTPCName == RTPCName)
			{
				VerticalBox.RemoveChild(Item);
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{	
		if (VerticalBox != nullptr)
		{
			for	(auto ItemObject: VerticalBox.GetAllChildren())
			{
				UAudioDebugMenuRTPCListItem Item = Cast<UAudioDebugMenuRTPCListItem>(ItemObject);
				if (Item.IsStatic)
					continue;
				
				FAudioRTPCItemData Data = Item.ElementData;

				float Value = -12345;
				ERTPCValueType OutputValueType;
				AkGameplay::GetRTPCValue(
					Data.PlayingId,
					Data.RTPCType, 
					Value, 
					OutputValueType, 
					Data.Actor, 
					Data.RTPCName);
				
				if (Value != -12345)
				{
					FGraphTimelineData Element;
					Element.Value = Value;
					Element.Duration = InDeltaTime;
					
					Item.UpdateRTPC(Value);
					GraphWidget.AddElement(Data.RTPCName.ToString(), Element);
				}
			}
		}
	}
}