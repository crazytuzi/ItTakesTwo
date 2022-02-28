class UUserInterfaceAudioDataAsset: UDataAsset
{	
	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnChangedSelectionEvent;

	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnChangedSelectionMouseOverEvent;

	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnChangedSelectionBackgroundMouseOverEvent;

	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnSelectEvent;

	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnConfirmEvent;

	UPROPERTY(Category = "Selection")
	UAkAudioEvent OnCancelEvent;		

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnSplashScreenBackgroundFadeIn;

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnSplashScreenTextFadeIn;

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnSplashScreenBackgroundFadeOut;

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnSplashScreenTextFadeOut;

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnSplashScreenConfirm;

	UPROPERTY(Category = "Splash Screen")
	UAkAudioEvent OnReturnToSplashScreen;

	UPROPERTY(Category = "Main")
	UAkAudioEvent OnReturnToMainMenuRoot;
	
	UPROPERTY(Category = "Main")
	UAkAudioEvent OnPopupMessageOpen;

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuOpen;

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuTabSelect;

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuRowSelect;	

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuSliderUpdate;

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuRadioButtonUpdate;

	UPROPERTY(Category = "Options Menu")
	UAkAudioEvent OnOptionsMenuClose;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnStartModeSelection;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnChapterSelectUpdateLevel;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnChapterSelectUpdateProgressPoint;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnPlayerJoin;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnPlayerLeave;

	UPROPERTY(Category = "Start Mode Select")	
	UAkAudioEvent OnProceedToCharacterSelect;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnReturnToChapterSelect;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnMoveSelectionMay;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnRemoveSelectionMay;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnConfirmSelectionMay;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnMoveSelectionCody;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnRemoveSelectionCody;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnConfirmSelectionCody;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnPlayerSelectedCharacterCancel;

	UPROPERTY(Category = "Character Select")
	UAkAudioEvent OnConfirmGameStarted;





}
