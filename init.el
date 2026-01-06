;; -*- lexical-binding: t; -*-
;; cf. https://github.com/jwiegley/dot-emacs/blob/master/init.org
;; cf. https://github.com/progfolio/.emacs.d/blob/master/init.org
;; cf. elpaca https://github.com/progfolio/elpaca
;; cf. https://blog.sumtypeofway.com/posts/emacs-config.html
;; cf. https://emacselements.com/gnus.html
(setq gc-cons-percentage 0.5
      gc-cons-threshold (* 128 1024 1024))

(defconst emacs-start-time (current-time))

(defun report-time-since-load (&optional suffix)
  (message "Loading init...done (%.3fs)%s"
           (float-time (time-subtract (current-time) emacs-start-time))
           suffix))

;; Report how long did it take to do all this.
(add-hook 'after-init-hook
          #'(lambda () (report-time-since-load " [after-init]"))
          t)

;; We need elpaca so that we can install the blimpy package.
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; Define the “data environment” for this instance of Emacs 
(eval-and-compile
  (defconst emacs-environment (getenv "NIX_MYENV_NAME"))
  )

;; Test if a host is available.
(defun quickping (host)
  (= 0 (call-process "ping" nil nil nil "-c1" "-W50" "-q" host)))


;; NOTE: these are only for people who wish to keep customizations with their accompanying use-package declarations.
;; Functionally, the only benefit over using setq in a :config block is that customizations might execute code when values are assigned.
;; We are following wiegly's set up and sequencing :custom -> :init -> :config. With the above comment explaining diff between :config and :custom.
(use-package emacs
  :ensure nil
  :demand t
  :bind*
  ("<C-return>" . other-window)
  ("<C-tabc>"    . ignore)  
  ("C-c e m"    . elpaca-manager)  ;; open the elpaca manager windo to try installing packages.
  :ensure nil
  :custom
  (user-full-name "Henry Lambert")
  (create-lockfiles nil)
  (auto-save-default nil)
  (make-backup-files nil)
  ;; simple.el
  (backward-delete-char-untabify-method 'untabify)
  (column-number-mode t)
  (global-display-line-numbers-mode t)
  (line-number-mode t)
  (kill-do-not-save-duplicates t)
  (kill-whole-line t)
  (indent-tabs-mode nil)
  (next-line-add-newlines nil)
  (save-interprogram-paste-before-kill t)


  ;; paragraphs.el
  (sentence-end-double-space nil)

  ;; paren.el
  (show-paren-delay 0)
  
  ;; window.el
  (same-window-buffer-names
   '("*eshell*"
     "*shell*"
     "*mail*"
     "*inferior-lisp*"
     "*ielm*"
     "*scheme*"))
  (switch-to-buffer-preserve-window-point t)

  ;; warnings.el
  (warning-minimum-log-level :error)

  ;; frame.el
  (window-divider-default-bottom-width 1)
  (window-divider-default-places 'bottom-only)
  
  
  :init
  (setq disabled-command-function nil) ;; enable all commands
  
  :config
  (setq ring-bell-function #'ignore)
  (setq custom-theme-directory "~/.emacs.d/themes/")

  (defun open-init-file ()
    "Open this very file."
    (interactive)
    (find-file "~/.emacs.d/init.el")
    )
  
  (defun open-help-notes ()
    "Open file with emacs notes."
    (interactive)
    (find-file "~/.emacs.d/log.org")
    )
  

  (defun insert-current-date ()
    "Insert the current date."
    (interactive)
    (insert (shell-command-to-string "echo -n $(date)"))
    (newline)
    (insert "-----------------------------")
    )

  (bind-key "C-c d" #'insert-current-date)
  (bind-key "C-c E" #'open-init-file)
  (bind-key "C-c H" #'open-help-notes)
  )



;; maybe we want to copy this to the .emacs.d/themes on install?
(use-package doom-themes
  :ensure t
  :custom
  (doom-challenger-deep-brighter-comments t)
  (doom-challenger-deep-brighter-modeline t)
  :config
  ;; Global settings (defaults)
  (setq custom-theme-directory "~/.emacs.d/themes/")
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-moonlight t)
  )

(use-package browse-url
  :bind (("C-c b" . browse-url-at-point))) ;;https://github.com/emacs-mirror/emacs/blob/master/lisp/net/browse-url.el

(use-package avy
  :ensure t
  :bind
  (("C-c l" . avy-goto-line) ;;This one is... nicee.
   ("C-c j" . avy-goto-char)) ;;This one is... ornate.
  )


(use-package haskell-mode
  :ensure t
  :mode (("\\.hs\\(c\\|-boot\\)?\\'" . haskell-mode)
         ("\\.lhs\\'" . haskell-literate-mode)
         ("\\.cabal\\'" . haskell-cabal-mode))
  )


;; Let the ihp-mode begin.
;; (elpaca (example :host github :repo "Montmorency/"))
(elpaca (ihp-mode :repo "~/projects/ihp-mode"))
        
;; And then there was phi-mode ...
;; (elpaca (phi-mode :repo "~/projects/phi-mode"))


(use-package jtsx
  :ensure t
  :mode (("\\.jsx?\\'" . jtsx-jsx-mode)
         ("\\.tsx\\'" . jtsx-tsx-mode)
         ("\\.ts\\'" . jtsx-typescript-mode))
  
  :commands jtsx-install-treesit-language ;; make sure we have tree sitter grammar.
  
  :hook ((jtsx-jsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . hs-minor-mode)
         (jtsx-typescript-mode . hs-minor-mode))
  ;; Optional customizations
  :custom
  (  (js-indent-level 4)
     (typescript-ts-mode-indent-offset 4)
     (jtsx-switch-indent-offset 2)
     (jtsx-enable-jsx-electric-closing-element t)
     (jtsx-enable-all-syntax-highlighting-features t)
     )
  
  :config
  (defun jtsx-bind-keys-to-mode-map (mode-map)
    "Bind keys to MODE-MAP."
    (define-key mode-map (kbd "C-c C-j") 'jtsx-jump-jsx-element-tag-dwim)
    (define-key mode-map (kbd "C-c j o") 'jtsx-jump-jsx-opening-tag)
    (define-key mode-map (kbd "C-c j c") 'jtsx-jump-jsx-closing-tag)
    (define-key mode-map (kbd "C-c j r") 'jtsx-rename-jsx-element)
    (define-key mode-map (kbd "C-c <down>") 'jtsx-move-jsx-element-tag-forward)
    (define-key mode-map (kbd "C-c <up>") 'jtsx-move-jsx-element-tag-backward)
    (define-key mode-map (kbd "C-c C-<down>") 'jtsx-move-jsx-element-forward)
    (define-key mode-map (kbd "C-c C-<up>") 'jtsx-move-jsx-element-backward)
    (define-key mode-map (kbd "C-c C-S-<down>") 'jtsx-move-jsx-element-step-in-forward)
    (define-key mode-map (kbd "C-c C-S-<up>") 'jtsx-move-jsx-element-step-in-backward)
    (define-key mode-map (kbd "C-c j w") 'jtsx-wrap-in-jsx-element)
    (define-key mode-map (kbd "C-c j u") 'jtsx-unwrap-jsx)
    (define-key mode-map (kbd "C-c j d n") 'jtsx-delete-jsx-node)
    (define-key mode-map (kbd "C-c j d a") 'jtsx-delete-jsx-attribute)
    (define-key mode-map (kbd "C-c j t") 'jtsx-toggle-jsx-attributes-orientation)
    (define-key mode-map (kbd "C-c j h") 'jtsx-rearrange-jsx-attributes-horizontally)
    (define-key mode-map (kbd "C-c j v") 'jtsx-rearrange-jsx-attributes-vertically))
  
  (defun jtsx-bind-keys-to-jtsx-jsx-mode-map ()
    (jtsx-bind-keys-to-mode-map jtsx-jsx-mode-map))

  (defun jtsx-bind-keys-to-jtsx-tsx-mode-map ()
    (jtsx-bind-keys-to-mode-map jtsx-tsx-mode-map))

  (add-hook 'jtsx-jsx-mode-hook 'jtsx-bind-keys-to-jtsx-jsx-mode-map)
  (add-hook 'jtsx-tsx-mode-hook 'jtsx-bind-keys-to-jtsx-tsx-mode-map)
  )  

;;https://github.com/syohex/emacs-terraform-mode
(use-package terraform-mode
  :ensure t
  :mode (("\\.tofu?\\" . terraform-mode))
  :custom
  ((terraform-command "tofu"))
  )


(use-package nix-mode
  :ensure t
  :mode ((".nix" . nix-mode))
  )

(report-time-since-load)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("0c83e0b50946e39e237769ad368a08f2cd1c854ccbcd1a01d39fdce4d6f86478"
     "dfcd2b13f10da4e5e26eb1281611e43a134d4400b06661445e7cbb183c47d2ec"
     "456697e914823ee45365b843c89fbc79191fdbaff471b29aad9dcbe0ee1d5641"
     "fd22a3aac273624858a4184079b7134fb4e97104d1627cb2b488821be765ff17"
     "b754d3a03c34cfba9ad7991380d26984ebd0761925773530e24d8dd8b6894738"
     "56044c5a9cc45b6ec45c0eb28df100d3f0a576f18eef33ff8ff5d32bac2d9700"
     "4d5d11bfef87416d85673947e3ca3d3d5d985ad57b02a7bb2e32beaf785a100e"
     "8d3ef5ff6273f2a552152c7febc40eabca26bae05bd12bc85062e2dc224cde9a"
     "e8183add41107592ee785f9f9b4b08d21bd6c43206b85bded889cea1ee231337"
     default)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:


